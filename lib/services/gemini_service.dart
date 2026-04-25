import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/constants.dart';
import 'json_parser.dart';
import 'observability_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Profile context used to personalise outfit & fit-check prompts.
/// All fields are optional; empty strings are skipped in the prompt.
class StyleProfileContext {
  final String? colorSeason;
  final List<String> colorPreferences;
  final String? bodyType;
  final List<String> aesthetics;
  final List<String> brands;
  final String? topSize;
  final String? bottomSize;
  final String? shoeSize;
  // Most-recent accept/reject signals — see outfit_feedback table.
  final List<String> recentAccepts;
  final List<String> recentRejects;

  const StyleProfileContext({
    this.colorSeason,
    this.colorPreferences = const [],
    this.bodyType,
    this.aesthetics = const [],
    this.brands = const [],
    this.topSize,
    this.bottomSize,
    this.shoeSize,
    this.recentAccepts = const [],
    this.recentRejects = const [],
  });

  String renderForPrompt() {
    final parts = <String>[];
    if (colorSeason != null && colorSeason!.isNotEmpty) {
      parts.add(
        'Color season: $colorSeason — pick colors that flatter this season.',
      );
    }
    if (colorPreferences.isNotEmpty) {
      parts.add('Favorite colors: ${colorPreferences.join(", ")}.');
    }
    if (bodyType != null && bodyType!.isNotEmpty) {
      parts.add(
        'Body type: $bodyType — favor silhouettes that flatter this shape.',
      );
    }
    if (aesthetics.isNotEmpty) {
      parts.add('Aesthetics she loves: ${aesthetics.join(", ")}.');
    }
    if (brands.isNotEmpty) {
      parts.add('Brands she shops: ${brands.join(", ")}.');
    }
    if (shoeSize != null && shoeSize!.isNotEmpty) {
      parts.add(
        'Shoe size: $shoeSize — only suggest shoes available in this size.',
      );
    }
    if (topSize != null || bottomSize != null) {
      parts.add(
        'Sizes — top: ${topSize ?? "?"}, bottom: ${bottomSize ?? "?"}.',
      );
    }
    if (recentAccepts.isNotEmpty) {
      parts.add('Recently loved looks: ${recentAccepts.take(5).join("; ")}.');
    }
    if (recentRejects.isNotEmpty) {
      parts.add(
        'Recently rejected looks (avoid these vibes): ${recentRejects.take(5).join("; ")}.',
      );
    }
    return parts.join('\n');
  }
}

/// Hard rules layered on top of the prompt depending on the occasion.
/// Prevents nonsense like "summer workout → strappy heels".
String _occasionConstraints(String occasion) {
  final o = occasion.toLowerCase();
  final rules = <String>[];

  // Anything athletic must be flat-soled, breathable, technical.
  if (o.contains('workout') ||
      o.contains('gym') ||
      o.contains('run') ||
      o.contains('athletic') ||
      o.contains('hike') ||
      o.contains('yoga')) {
    rules.add(
      '- ATHLETIC OCCASION: shoes MUST be sneakers or technical trainers. NO heels, NO sandals, NO loafers, NO flats with bows. NO blazers, NO clutches, NO statement jewelry. Pick performance fabric (cotton, technical, knit), not silk/satin.',
    );
  }
  if (o.contains('beach') || o.contains('pool')) {
    rules.add(
      '- BEACH/POOL: swimwear or breathable cover-up + sandals/flat slides. NO heels, NO heavy jewelry that tarnishes in salt water.',
    );
  }
  if (o.contains('summer') || o.contains('hot') || o.contains('warm')) {
    rules.add(
      '- WARM WEATHER: NO heavy outerwear, NO knits, NO boots. Light fabrics (linen, cotton, silk).',
    );
  }
  if (o.contains('winter') || o.contains('snow') || o.contains('cold')) {
    rules.add(
      '- COLD WEATHER: include a coat or layered outerwear. NO open-toe shoes, NO bare legs without tights.',
    );
  }
  if (o.contains('rain') || o.contains('wet')) {
    rules.add(
      '- RAINY WEATHER: closed-toe waterproof shoes only. Suggest a trench or rain layer.',
    );
  }
  if (o.contains('work') ||
      o.contains('office') ||
      o.contains('meeting') ||
      o.contains('interview')) {
    rules.add(
      '- WORK/OFFICE: tailored, polished. NO crop tops showing midriff, NO ultra-mini skirts, NO see-through fabrics. Closed-toe or low-block-heel.',
    );
  }
  if (o.contains('formal') || o.contains('wedding') || o.contains('gala')) {
    rules.add(
      '- FORMAL: midi or floor-length dress, or elevated suit. Heels or dressy flats. Statement jewelry encouraged.',
    );
  }
  if (o.contains('date') && !o.contains('first')) {
    rules.add(
      '- DATE: feminine, elevated. One statement piece (top OR shoes OR bag), not all three.',
    );
  }

  if (rules.isEmpty) return '';
  return '\n═══ HARD OCCASION RULES — DO NOT BREAK ═══\n${rules.join("\n")}\n';
}

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

  Future<http.Response> _postToGemini(Map<String, dynamic> body) async {
    String authToken = AppConstants.supabaseAnonKey;
    try {
      final session = sb.Supabase.instance.client.auth.currentSession;
      if (session?.accessToken != null && session!.accessToken.isNotEmpty) {
        authToken = session.accessToken;
      }
    } catch (_) {
      // Supabase not initialized — fall back to anon key.
    }

    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_proxyUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $authToken',
                'apikey': AppConstants.supabaseAnonKey,
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 401) {
          throw const GeminiAuthException(
            'Your session has expired. Please sign out and sign back in.',
          );
        }
        if (response.statusCode == 429) {
          throw GeminiRateLimitException(
            _extractErrorMessage(response.body) ??
                'You have hit today\'s AI usage limit. It resets at midnight UTC.',
          );
        }
        if (response.statusCode == 413) {
          throw const GeminiInputTooLargeException(
            'That image or prompt is too large. Try a smaller photo.',
          );
        }
        if (response.statusCode >= 500 && attempt < 2) {
          await Future.delayed(Duration(milliseconds: 400 * (1 << attempt)));
          continue;
        }
        return response;
      } on GeminiRateLimitException {
        rethrow;
      } on GeminiAuthException {
        rethrow;
      } on GeminiInputTooLargeException {
        rethrow;
      } catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 400 * (1 << attempt)));
          continue;
        }
      }
    }
    throw GeminiNetworkException(
      'Could not reach the AI service. Check your connection and try again. ($lastError)',
    );
  }

  String? _extractErrorMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['error'] is String) return j['error'] as String;
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _parseAiResponse(http.Response response, String op) {
    final body = jsonDecode(response.body);
    final text =
        body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null || text.isEmpty) {
      throw GeminiResponseException(
        'AI returned an empty response for $op. Try again in a moment.',
      );
    }
    try {
      return parseTolerantJson(text);
    } on JsonParseFailure catch (e) {
      // Log to Sentry — every recurrence helps us tighten the prompt
      Observability.captureMessage(
        'Gemini JSON parse failed for $op',
        extra: {'sample': e.rawSample},
      );
      throw GeminiResponseException(
        'AI gave a malformed answer. Tap retry — it usually clears up.',
      );
    }
  }

  Future<ColorSeasonResult> analyzeColorSeason(Uint8List selfieImage) async {
    if (!isGeminiConfigured) {
      throw const GeminiApiKeyException(
        'AI color analysis is not configured on the server yet. Please try again later.',
      );
    }

    final resized = _resizeAndEncodeJpeg(selfieImage);
    final base64Image = base64Encode(resized);

    final response = await _postToGemini({
      'model': 'gemini-2.5-flash',
      'contents': [
        {
          'parts': [
            {
              'text':
                  '''You are a professional color analyst trained in Johannes Itten's color temperature theory and Carole Jackson's "Color Me Beautiful" 4-season system.

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

Respond with ONLY valid JSON (no markdown, no extra text, no leading "JSON" label):
{
  "season": "<SPRING|SUMMER|AUTUMN|WINTER>",
  "confidence": <number 60-99>,
  "tagline": "<8-12 word poetic description of their coloring>",
  "reasoning": "<2-3 sentences explaining exactly what you observed in the photo>",
  "skin_observation": "<one sentence about skin undertone>",
  "hair_observation": "<one sentence about hair coloring>",
  "eye_observation": "<one sentence about eye color>",
  "contrast_level": "<Low|Medium|High>"
}''',
            },
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 512},
    });

    if (response.statusCode == 429) {
      throw const GeminiRateLimitException(
        'Too many requests — the free tier allows 5 analyses per minute.\n'
        'Wait 60 seconds and try again, or pick your season manually below.',
      );
    }
    if (response.statusCode != 200) {
      throw GeminiResponseException(
        'Gemini API error ${response.statusCode}: ${response.body}',
      );
    }

    final result = _parseAiResponse(response, 'color_season');

    return ColorSeasonResult(
      season: ((result['season'] ?? 'autumn') as String).toLowerCase(),
      confidence: (result['confidence'] as num?)?.toInt() ?? 70,
      tagline: result['tagline'] as String? ?? '',
      reasoning: result['reasoning'] as String? ?? '',
      skinObservation: result['skin_observation'] as String? ?? '',
      hairObservation: result['hair_observation'] as String? ?? '',
      eyeObservation: result['eye_observation'] as String? ?? '',
      contrastLevel: result['contrast_level'] as String? ?? 'Medium',
    );
  }

  Uint8List _resizeAndEncodeJpeg(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final resized = decoded.width > 800 || decoded.height > 800
          ? img.copyResize(
              decoded,
              width: decoded.width > decoded.height ? 800 : -1,
              height: decoded.height >= decoded.width ? 800 : -1,
            )
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return bytes;
    }
  }

  /// Image-based fit check — kept for future "selfie wearing the outfit" flow.
  Future<FitCheckResult> scoreFitCheck(Uint8List outfitImage) async {
    final base64Image = base64Encode(outfitImage);

    final response = await _postToGemini({
      'model': AppConstants.geminiModel,
      'contents': [
        {
          'parts': [
            {
              'text':
                  '''You are a women's fashion stylist. Rate this outfit 1-100. Respond with ONLY valid JSON (no leading "JSON" label, no markdown):
{"score": <number 1-100>, "feedback": "<2-3 sentences of constructive feedback>"}''',
            },
            {
              'inline_data': {'mime_type': 'image/png', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 256},
    });

    if (response.statusCode != 200) {
      throw GeminiResponseException(
        'Gemini API error: ${response.statusCode} ${response.body}',
      );
    }

    final result = _parseAiResponse(response, 'fit_check_image');
    return FitCheckResult(
      score: (result['score'] as num?)?.toInt() ?? 70,
      feedback: result['feedback'] as String? ?? '',
    );
  }

  /// Text-based fit check — used by the Fit Check screen. Sends the list of
  /// outfit items + occasion + profile and returns a structured rich result.
  Future<RichFitCheckResult> scoreFitCheckFromItems({
    required String occasion,
    required List<Map<String, String>> items, // [{name, color, category}]
    required StyleProfileContext profile,
  }) async {
    if (!isGeminiConfigured) {
      throw const GeminiApiKeyException(
        'AI fit check is not configured on the server yet. Please try again later.',
      );
    }
    if (items.isEmpty) {
      throw const GeminiResponseException(
        'This outfit has no items to analyze. Add at least one piece first.',
      );
    }

    final itemList = items
        .map(
          (i) =>
              '- ${i["name"] ?? i["category"]} '
              '(${i["color"] ?? "unspecified"}, ${i["category"]})',
        )
        .join('\n');

    final profilePart = profile.renderForPrompt();
    final constraints = _occasionConstraints(occasion);

    final prompt =
        '''You are a women's fashion stylist scoring a real outfit. Be honest, kind, and specific.

OCCASION: $occasion

OUTFIT ITEMS:
$itemList

USER PROFILE:
${profilePart.isEmpty ? '(no profile data)' : profilePart}
$constraints
Score the outfit on FOUR criteria, 0-100 each:
1. color_harmony — do the colors work together AND flatter the user's color season?
2. style_cohesion — do the items match in formality and vibe?
3. occasion_fit — is this appropriate for "$occasion"? (penalize hard if it breaks an Occasion Rule above)
4. versatility — could she re-wear these pieces in other contexts?

Then compute overall as a weighted average (color_harmony 0.25, style_cohesion 0.30, occasion_fit 0.30, versatility 0.15), rounded to nearest integer.

Respond with ONLY valid JSON. No markdown fences. No leading "JSON" label.
{
  "overall": <0-100>,
  "color_harmony": <0-100>,
  "style_cohesion": <0-100>,
  "occasion_fit": <0-100>,
  "versatility": <0-100>,
  "headline": "<5-8 word verdict like 'Polished, day-to-night ready'>",
  "feedback": "<2-3 sentences: what works, what to consider>",
  "tips": [
    "<actionable tip 1>",
    "<actionable tip 2>",
    "<actionable tip 3>"
  ]
}''';

    final response = await _postToGemini({
      'model': 'gemini-2.5-flash',
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.6, 'maxOutputTokens': 600},
    });

    if (response.statusCode == 429) {
      throw const GeminiRateLimitException('Daily AI quota reached.');
    }
    if (response.statusCode != 200) {
      throw GeminiResponseException(
        'Gemini API error: ${response.statusCode} ${response.body}',
      );
    }

    final result = _parseAiResponse(response, 'fit_check_text');

    int clamp(num? n, [int fallback = 75]) {
      if (n == null) return fallback;
      final v = n.toInt();
      return v < 0 ? 0 : (v > 100 ? 100 : v);
    }

    return RichFitCheckResult(
      overall: clamp(result['overall']),
      colorHarmony: clamp(result['color_harmony']),
      styleCohesion: clamp(result['style_cohesion']),
      occasionFit: clamp(result['occasion_fit']),
      versatility: clamp(result['versatility']),
      headline: result['headline'] as String? ?? 'Solid fit',
      feedback:
          result['feedback'] as String? ??
          'A workable look — small tweaks will lift it further.',
      tips: ((result['tips'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  /// Outfit generation — now profile-aware, occasion-rule-aware, and
  /// surfaces honest errors instead of silently dropping to a fake fallback.
  Future<GeminiOutfitResult> generateOutfit({
    required String occasion,
    StyleProfileContext? profile,
    String? colorSeason, // legacy positional, folded into profile
    String? weather,
    List<Map<String, String>>? items,
    bool fromScratch = false,
  }) async {
    if (!isGeminiConfigured) {
      throw const GeminiApiKeyException(
        'AI outfit generation is not configured on the server yet.',
      );
    }

    final ctx = profile ?? StyleProfileContext(colorSeason: colorSeason);

    final itemContext = items != null && items.isNotEmpty
        ? 'User wardrobe items:\n${items.map((i) => '- ${i['name']} (${i['color']}, ${i['category']}) id:${i['id']}').join('\n')}'
        : 'Generate a completely fresh trending look (no specific wardrobe items).';

    final profilePart = ctx.renderForPrompt();
    final weatherCtx = weather != null
        ? 'Current weather: $weather. Adapt layers/fabric choices accordingly.'
        : '';
    final constraints = _occasionConstraints(occasion);

    final prompt =
        '''You are an expert WOMEN'S fashion stylist with encyclopedic knowledge of current trends, runway collections, streetwear culture, and modern color theory. You style EXCLUSIVELY for women — never use menswear terminology (no "button-up shirt for him", no "men's loafers", no "boyfriend tee"). Reference brands women actually shop: Zara, Aritzia, Free People, Revolve, SHEIN, Skims, Mango, Uniqlo, Anthropologie, Fashion Nova, Mejuri, Steve Madden, Reformation, Madewell.

═══ CLOTHING TERMINOLOGY — USE THESE PRECISELY ═══
TOPS: crop top, bralette, blouse, silk button-down, tank top, camisole, bodysuit, tube top, off-shoulder top, corset top, bustier, cardigan wrap, ribbed tee, puff-sleeve blouse
BOTTOMS: mini/midi/maxi skirt, tennis skirt, pleated skirt, satin skirt, mini shorts, bermuda shorts, wide-leg trousers, straight-leg jeans, skinny jeans, mom jeans, cargo pants, flare pants, leggings, cycling shorts
DRESSES: mini, midi, maxi, bodycon, wrap, slip, sundress, sheath, A-line, shirt, tiered, cami
OUTERWEAR: oversized blazer, cropped blazer, trench, puffer, shearling, denim jacket, leather moto, cardigan, kimono
SHOES: strappy heeled sandals, block-heeled mules, pointed-toe pumps, kitten-heel slingbacks, ankle boots, knee-high boots, western boots, platform sneakers, ballet flats, loafers, gladiator sandals, Mary Janes, technical trainers, running shoes
BAGS: mini crossbody, structured tote, clutch, baguette, bucket bag, hobo, top-handle, shoulder bag, saddle bag
ACCESSORIES: pendant necklace, layered chains, hoops, studs, statement earrings, huggies, stacking rings, signet, chunky bracelet, tennis bracelet, anklet, cat-eye sunglasses, silk scarf, hair claw, belt, beret
TRENDS (2025-2026): quiet luxury, coquette, Y2K revival, "clean girl", Scandi minimalism, balletcore, cowboy-chic, western revival, mob-wife glam, athleisure-elevated

═══ CRITICAL RULES ═══
1. EVERY outfit must include: top/dress + bottom (unless dress) + shoes + bag + at least 2 accessories.
2. Minimum 5 items. Ideal: 6-7.
3. Women's styling — never describe items as unisex or menswear-coded.
4. Match occasion EXACTLY — see hard rules below.
5. Use item names EXACTLY as given — never rename existing wardrobe items.
6. If profile lists shoe size, only suggest shoes plausibly available in that size.
7. Honor the user's recently rejected vibes — don't repeat them.

Occasion: $occasion
$weatherCtx

USER STYLE PROFILE:
${profilePart.isEmpty ? '(no profile data — use sensible defaults)' : profilePart}

$itemContext
$constraints
${fromScratch ? '''Design a complete, on-trend women's outfit from scratch. Include:
- 1 top OR dress
- 1 bottom (if top, not dress)
- 1 pair of shoes
- 1 bag
- At least 2 jewelry/accessory pieces
- Optional: 1 layer''' : 'Select WOMEN\'S items from the wardrobe above. Pick at least 5 items: top/dress, bottom (if no dress), shoes, bag, and 2+ accessories. Note any missing slot.'}

Respond with ONLY valid JSON (no markdown, no leading "JSON" label):
{
  "title": "<3-5 word outfit name reflecting the trend>",
  "reasoning": "<2-3 sentences: why this works for occasion + season + trend>",
  "styleScore": <7-10>,
  "selectedItemIds": [<item ids — must include shoes, bag, 2+ accessories>],
  "trendNote": "<one sentence: which 2025/2026 trend inspired this>",
  "suggestions": "<missing-slot shopping advice OR styling tips>"
}''';

    try {
      final response = await _postToGemini({
        'model': 'gemini-2.5-flash',
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.85, 'maxOutputTokens': 600},
      });

      if (response.statusCode == 429) {
        throw const GeminiRateLimitException('Daily AI quota reached.');
      }
      if (response.statusCode != 200) {
        throw GeminiResponseException(
          'Gemini API error: ${response.statusCode}.',
        );
      }

      final result = _parseAiResponse(response, 'outfit_generation');

      return GeminiOutfitResult(
        title: result['title'] as String? ?? '$occasion Look',
        reasoning: result['reasoning'] as String? ?? '',
        styleScore: (result['styleScore'] as num?)?.toInt() ?? 8,
        selectedItemIds:
            (result['selectedItemIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        trendNote: result['trendNote'] as String? ?? '',
        suggestions: result['suggestions'] as String? ?? '',
      );
    } on GeminiRateLimitException {
      rethrow;
    } on GeminiAuthException {
      rethrow;
    } on GeminiInputTooLargeException {
      rethrow;
    } on GeminiNetworkException {
      rethrow;
    } on GeminiResponseException {
      rethrow;
    }
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

class RichFitCheckResult {
  final int overall;
  final int colorHarmony;
  final int styleCohesion;
  final int occasionFit;
  final int versatility;
  final String headline;
  final String feedback;
  final List<String> tips;

  const RichFitCheckResult({
    required this.overall,
    required this.colorHarmony,
    required this.styleCohesion,
    required this.occasionFit,
    required this.versatility,
    required this.headline,
    required this.feedback,
    required this.tips,
  });
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

class GeminiAuthException implements Exception {
  final String message;
  const GeminiAuthException(this.message);
  @override
  String toString() => message;
}

class GeminiInputTooLargeException implements Exception {
  final String message;
  const GeminiInputTooLargeException(this.message);
  @override
  String toString() => message;
}

class GeminiNetworkException implements Exception {
  final String message;
  const GeminiNetworkException(this.message);
  @override
  String toString() => message;
}

class GeminiResponseException implements Exception {
  final String message;
  const GeminiResponseException(this.message);
  @override
  String toString() => message;
}

class ColorSeasonResult {
  final String season;
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
