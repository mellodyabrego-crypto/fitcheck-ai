import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../core/constants.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  /// URL of the Supabase edge function that proxies Gemini calls.
  /// The browser never sees the Gemini API key — only the Supabase anon key.
  static String get _proxyUrl {
    final sb = AppConstants.supabaseUrl;
    if (sb.isEmpty) return '';
    return '${sb.replaceAll(RegExp(r'/+$'), '')}/functions/v1/gemini-proxy';
  }

  /// The proxy is considered configured as long as Supabase is configured.
  /// The actual Gemini key lives server-side as an Edge Function secret.
  bool get isGeminiConfigured {
    return _proxyUrl.isNotEmpty && AppConstants.supabaseAnonKey.isNotEmpty;
  }

  /// POST a Gemini request through the Supabase edge function.
  /// `body` should include {'model': '...', 'contents': [...], ...}.
  Future<http.Response> _postToGemini(Map<String, dynamic> body) async {
    return http.post(
      Uri.parse(_proxyUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
        'apikey': AppConstants.supabaseAnonKey,
      },
      body: jsonEncode(body),
    );
  }

  Future<ColorSeasonResult> analyzeColorSeason(Uint8List selfieImage) async {
    if (!isGeminiConfigured) {
      throw const GeminiApiKeyException(
        'AI color analysis is not configured on the server yet. Please try again later.',
      );
    }

    // Resize image to max 800px and convert to JPEG for consistent delivery
    // (image_picker ignores maxWidth/maxHeight on Flutter Web)
    final resized = _resizeAndEncodeJpeg(selfieImage);
    final base64Image = base64Encode(resized);

    final response = await _postToGemini({
      'model': 'gemini-2.5-flash',
      'contents': [
          {
            'parts': [
              {
                'text': '''You are a professional color analyst trained in Johannes Itten's color temperature theory and Carole Jackson's "Color Me Beautiful" 4-season system.

Analyze this person's natural coloring carefully. Look at:
1. SKIN UNDERTONE: Is it warm (yellow/golden/peachy) or cool (pink/rosy/bluish)?
2. SKIN VALUE: Light, medium, or deep?
3. HAIR COLOR & WARMTH: Is the hair warm (golden, auburn, red, warm brown) or cool (ash, platinum, blue-black)?
4. EYE COLOR: Warm (brown, hazel, olive, warm green) or cool (blue, grey, cool green)?
5. CONTRAST: Low (features blend together) or high (strong contrast between hair, eyes, skin)?

Based on Carole Jackson's system, assign ONE of these 4 seasons:

SPRING: Warm undertone + clear/bright coloring + low-to-medium contrast. Golden skin, golden/strawberry blonde/light auburn hair, clear eyes (blue, green, hazel with gold flecks). Best colors: peach, coral, warm pink, golden yellow, ivory, camel, warm tan, moss green.

SUMMER: Cool undertone + soft/muted coloring + low contrast. Pink/rosy skin, ash blonde/brown/cool brown hair, soft eyes (grey-blue, soft brown, rose-brown). Best colors: dusty rose, lavender, soft blue, periwinkle, mauve, powder blue, soft grey, light navy.

AUTUMN: Warm undertone + muted/rich coloring + medium-to-high contrast. Golden/olive/bronze skin, auburn/chestnut/warm brown/dark hair with warmth, hazel/brown/olive green eyes. Best colors: rust, burnt orange, olive, terracotta, forest green, mustard, camel, chocolate.

WINTER: Cool undertone + clear/bright OR deep coloring + high contrast. Pink/blue-tinted skin (can be deep ebony to porcelain), blue-black/dark cool brown/silver hair, dark brown/black/cool grey or icy blue eyes. Best colors: true red, royal blue, black, crisp white, emerald, burgundy, charcoal, icy pink.

Respond with ONLY valid JSON (no markdown, no extra text):
{
  "season": "<SPRING|SUMMER|AUTUMN|WINTER>",
  "confidence": <number 60-99>,
  "tagline": "<8-12 word poetic description of their coloring, e.g. 'Golden warmth with a sun-kissed glow'>",
  "reasoning": "<2-3 sentences explaining exactly what you observed in the photo>",
  "skin_observation": "<one sentence about skin undertone>",
  "hair_observation": "<one sentence about hair coloring>",
  "eye_observation": "<one sentence about eye color>",
  "contrast_level": "<Low|Medium|High>"
}''',
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 512,
        },
    });

    if (response.statusCode == 429) {
      throw const GeminiRateLimitException(
        'Too many requests — the free tier allows 5 analyses per minute.\n'
        'Wait 60 seconds and try again, or pick your season manually below.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body);
    final text = body['candidates'][0]['content']['parts'][0]['text'] as String;

    final jsonStr = _extractJson(text);
    final result = jsonDecode(jsonStr) as Map<String, dynamic>;

    return ColorSeasonResult(
      season: (result['season'] as String).toLowerCase(),
      confidence: (result['confidence'] as num).toInt(),
      tagline: result['tagline'] as String,
      reasoning: result['reasoning'] as String,
      skinObservation: result['skin_observation'] as String? ?? '',
      hairObservation: result['hair_observation'] as String? ?? '',
      eyeObservation: result['eye_observation'] as String? ?? '',
      contrastLevel: result['contrast_level'] as String? ?? 'Medium',
    );
  }

  // Resize image to max 800px wide/tall and encode as JPEG
  // Needed because image_picker ignores size params on Flutter Web
  Uint8List _resizeAndEncodeJpeg(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final resized = decoded.width > 800 || decoded.height > 800
          ? img.copyResize(decoded, width: decoded.width > decoded.height ? 800 : -1, height: decoded.height >= decoded.width ? 800 : -1)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return bytes; // fall back to original if resize fails
    }
  }

  Future<FitCheckResult> scoreFitCheck(Uint8List outfitImage) async {
    final base64Image = base64Encode(outfitImage);

    final response = await _postToGemini({
      'model': AppConstants.geminiModel,
      'contents': [
          {
            'parts': [
              {
                'text': '''You are a fashion expert. Rate this outfit on a scale of 1-100 and provide brief feedback.

Consider:
- Color harmony and coordination
- Style cohesion (do the pieces match in formality/vibe?)
- Overall visual appeal
- Versatility

Respond with ONLY valid JSON:
{"score": <number 1-100>, "feedback": "<2-3 sentences of constructive feedback>"}''',
              },
              {
                'inline_data': {
                  'mime_type': 'image/png',
                  'data': base64Image,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 256,
        },
    });

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body);
    final text = body['candidates'][0]['content']['parts'][0]['text'] as String;

    final jsonStr = _extractJson(text);
    final result = jsonDecode(jsonStr) as Map<String, dynamic>;

    return FitCheckResult(
      score: (result['score'] as num).toInt(),
      feedback: result['feedback'] as String,
    );
  }

  /// Generate a trend-based outfit concept using Gemini text generation.
  /// [items] is a JSON-serializable list of wardrobe items (or null for scratch).
  /// [colorSeason] is e.g. 'Autumn', [weather] is e.g. 'Sunny, 75°F'.
  Future<GeminiOutfitResult> generateOutfit({
    required String occasion,
    String? colorSeason,
    String? weather,
    List<Map<String, String>>? items, // [{id, name, color, category, slot}]
    bool fromScratch = false,
  }) async {
    if (!isGeminiConfigured) {
      return _fallbackOutfit(occasion, colorSeason);
    }

    final itemContext = items != null && items.isNotEmpty
        ? 'User wardrobe items:\n${items.map((i) => '- ${i['name']} (${i['color']}, ${i['category']}) id:${i['id']}').join('\n')}'
        : 'Generate a completely fresh trending look (no specific wardrobe items).';

    final paletteCtx = colorSeason != null
        ? 'User color season: $colorSeason. Choose colors that complement this season.'
        : '';

    final weatherCtx = weather != null
        ? 'Current weather: $weather. Adapt layers/fabric choices accordingly.'
        : '';

    final prompt = '''You are an expert WOMEN'S fashion stylist with encyclopedic knowledge of current trends, runway collections, streetwear culture, and modern color theory. You style exclusively for women — never use menswear terminology (e.g. never say "button-up shirt for him", "men's loafers"). Reference brands women actually shop: Zara, Aritzia, Free People, Revolve, SHEIN, Skims, Mango, Uniqlo, Victoria's Secret, Aritzia, Anthropologie, Fashion Nova, Mejuri, Steve Madden.

═══ CLOTHING TERMINOLOGY — USE THESE PRECISELY ═══
TOPS: crop top (ends above navel), bralette, blouse (loose/flowy), silk button-down, tank top, camisole, bodysuit, tube top, off-shoulder top, corset top, bustier, cardigan wrap, ribbed tee, puff-sleeve blouse
BOTTOMS: mini/midi/maxi skirt, tennis skirt, pleated skirt, satin skirt, mini shorts, bermuda shorts, wide-leg trousers, straight-leg jeans, skinny jeans, mom jeans, cargo pants, flare pants, leggings, cycling shorts
DRESSES: mini dress, midi dress, maxi dress, bodycon dress, wrap dress, slip dress, sundress, sheath dress, A-line dress, shirt dress, tiered dress, cami dress
OUTERWEAR: oversized blazer, cropped blazer, trench coat, puffer, shearling coat, denim jacket, leather moto jacket, cardigan, kimono
SHOES: strappy heeled sandals, block-heeled mules, pointed-toe pumps, kitten-heel slingbacks, ankle boots, knee-high boots, western boots, platform sneakers, ballet flats, loafers, gladiator sandals, Mary Janes
BAGS: mini crossbody, structured tote, clutch, baguette, bucket bag, hobo, top-handle, shoulder bag, saddle bag
ACCESSORIES (jewelry + more): pendant necklace, layered chain necklace, hoop earrings, stud earrings, statement earrings, huggie earrings, stacking rings, signet ring, chunky bracelet, tennis bracelet, dainty anklet, cat-eye sunglasses, silk scarf, hair claw clip, belt (waist/hip), beret
TRENDS TO REFERENCE (as of 2025): quiet luxury, coquette, Y2K revival, "clean girl" aesthetic, Scandi minimalism, balletcore, cowboy-chic, western revival, tomato girl summer, mob-wife glam

═══ CRITICAL RULES ═══
1. EVERY outfit must include ALL of: top/dress + bottom (unless dress) + shoes + bag + at least 2 accessories (one of which is a necklace or earrings).
2. Minimum 5 items per outfit. Ideal: 6-7 (add a jacket/layer or second accessory).
3. Women's styling — never describe items as unisex or menswear-coded.
4. Match occasion: work → tailored + polished; date night → elevated + statement; casual → relaxed + layered; party → bold + sparkle.
5. Use item names EXACTLY as given — never rename.

Occasion: $occasion
$paletteCtx
$weatherCtx
$itemContext

${fromScratch ? '''Design a complete, on-trend women's outfit from scratch. Pick a real trend from the list above. YOU MUST INCLUDE:
- 1 top OR dress
- 1 bottom if you chose top (otherwise skip)
- 1 pair of shoes (exact style — strappy heels vs ankle boots vs loafers, etc.)
- 1 bag (exact style — clutch vs crossbody vs tote)
- At least 2 jewelry pieces (e.g. layered gold chain + small hoops + stacking rings)
- Optional: 1 layer (cardigan, blazer, trench)''' : 'Select WOMEN\'S items from the wardrobe list above. You MUST pick at least 5 items covering: top/dress, bottom (if no dress), shoes, bag, and at least 2 accessories. If the wardrobe is missing a slot, still select what\'s there and mention what is missing in suggestions.'}

Respond with ONLY valid JSON (no markdown fences):
{
  "title": "<catchy 3-5 word outfit name reflecting the trend>",
  "reasoning": "<2-3 sentences: why this works for the occasion + color season + current trend>",
  "styleScore": <7-10>,
  "selectedItemIds": [<item ids — MUST include ids for shoes, bag, and 2+ accessories>],
  "trendNote": "<one sentence: which 2025 trend inspired this>",
  "suggestions": "<if any slot is missing from the wardrobe, name what to shop for; otherwise add styling tips (e.g. 'tuck the top in, roll sleeves')>"
}''';

    try {
      final response = await _postToGemini({
        'model': 'gemini-2.5-flash',
        'contents': [
          {'parts': [{'text': prompt}]}
        ],
        'generationConfig': {'temperature': 0.9, 'maxOutputTokens': 512},
      });

      if (response.statusCode == 429) throw const GeminiRateLimitException('Rate limit hit');
      if (response.statusCode != 200) return _fallbackOutfit(occasion, colorSeason);

      final body = jsonDecode(response.body);
      final text = body['candidates'][0]['content']['parts'][0]['text'] as String;
      final jsonStr = _extractJson(text);
      final result = jsonDecode(jsonStr) as Map<String, dynamic>;

      return GeminiOutfitResult(
        title: result['title'] as String? ?? '$occasion Outfit',
        reasoning: result['reasoning'] as String? ?? '',
        styleScore: (result['styleScore'] as num?)?.toInt() ?? 8,
        selectedItemIds: (result['selectedItemIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        trendNote: result['trendNote'] as String? ?? '',
        suggestions: result['suggestions'] as String? ?? '',
      );
    } catch (_) {
      return _fallbackOutfit(occasion, colorSeason);
    }
  }

  GeminiOutfitResult _fallbackOutfit(String occasion, String? colorSeason) {
    final palette = colorSeason ?? 'warm';
    return GeminiOutfitResult(
      title: '${occasion[0].toUpperCase()}${occasion.substring(1)} Look',
      reasoning:
          'A curated $occasion look with colors that complement your $palette palette. '
          'Clean silhouettes and cohesive tones keep the overall look polished and effortless.',
      styleScore: 8,
      selectedItemIds: [],
      trendNote: 'Minimalist-chic is trending across FashionNova and social media this season.',
      suggestions: 'Add a gold-toned accessory to elevate the look and tie the palette together.',
    );
  }

  String _extractJson(String text) {
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (codeBlockMatch != null) return codeBlockMatch.group(1)!.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1) return text.substring(start, end + 1);

    return text;
  }
}

class GeminiOutfitResult {
  final String title;
  final String reasoning;
  final int styleScore;
  final List<String> selectedItemIds;
  final String trendNote;
  final String suggestions;

  const GeminiOutfitResult({
    required this.title,
    required this.reasoning,
    required this.styleScore,
    required this.selectedItemIds,
    required this.trendNote,
    required this.suggestions,
  });
}

class FitCheckResult {
  final int score;
  final String feedback;

  const FitCheckResult({required this.score, required this.feedback});
}

class GeminiRateLimitException implements Exception {
  final String message;
  const GeminiRateLimitException(this.message);
  @override
  String toString() => message;
}

class GeminiApiKeyException implements Exception {
  final String message;
  const GeminiApiKeyException(this.message);
  @override
  String toString() => message;
}

class ColorSeasonResult {
  final String season; // 'spring' | 'summer' | 'autumn' | 'winter'
  final int confidence;
  final String tagline;
  final String reasoning;
  final String skinObservation;
  final String hairObservation;
  final String eyeObservation;
  final String contrastLevel;

  const ColorSeasonResult({
    required this.season,
    required this.confidence,
    required this.tagline,
    required this.reasoning,
    required this.skinObservation,
    required this.hairObservation,
    required this.eyeObservation,
    required this.contrastLevel,
  });
}
