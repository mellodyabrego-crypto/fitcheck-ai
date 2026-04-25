import 'dart:convert';

/// Tolerant JSON extractor for AI responses.
///
/// Gemini occasionally wraps JSON in:
///   * markdown fences:    ```json\n{ ... }\n```
///   * leading labels:     "JSON\n{ ... }"
///   * explanation text:   "Here is the response: { ... }"
///   * smart quotes:       “ ” instead of " "
///   * trailing commas:    { "a": 1, }
///
/// The "unrecognized token JSON" error users have hit comes from
/// `jsonDecode` choking on the literal word "JSON" before the brace.
/// This helper strips the noise, normalises quotes, and tries a sequence
/// of recovery passes before giving up.
///
/// Returns a `Map<String, dynamic>`. Throws `JsonParseFailure` (with the
/// raw text attached for logging) if every recovery pass fails — callers
/// should surface that to the user as an honest error, not a silent fallback.
class JsonParseFailure implements Exception {
  final String message;
  final String rawSample;
  const JsonParseFailure(this.message, this.rawSample);
  @override
  String toString() => 'JsonParseFailure: $message';
}

Map<String, dynamic> parseTolerantJson(String text) {
  final attempts = <String>[];

  // 1. Markdown fence
  final fence = RegExp(r'```(?:json|JSON)?\s*([\s\S]*?)```').firstMatch(text);
  if (fence != null) attempts.add(fence.group(1)!.trim());

  // 2. First "{" to last "}"
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start != -1 && end != -1 && end > start) {
    attempts.add(text.substring(start, end + 1));
  }

  // 3. Whole text as-is
  attempts.add(text.trim());

  for (final raw in attempts) {
    final candidates = _normalizeCandidates(raw);
    for (final c in candidates) {
      try {
        final decoded = jsonDecode(c);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // try the next candidate
      }
    }
  }

  final sample = text.length > 400 ? '${text.substring(0, 400)}…' : text;
  throw JsonParseFailure('Could not parse AI response as JSON.', sample);
}

// ASCII-only source. We build the zero-width / BOM character set at runtime
// from explicit codepoints so editors / line-ending normalisers can't re-encode
// or strip literal codepoints embedded in the regex.
//   200B zero-width space
//   200C zero-width non-joiner
//   200D zero-width joiner
//   2060 word joiner
//   FEFF byte order mark
final _kZeroWidthChars = String.fromCharCodes(const [
  0x200B,
  0x200C,
  0x200D,
  0x2060,
  0xFEFF,
]);
final _kZeroWidthRegex = RegExp('[$_kZeroWidthChars]');

Iterable<String> _normalizeCandidates(String raw) sync* {
  // Original
  yield raw;

  final stripped = raw.replaceAll(_kZeroWidthRegex, '');
  if (stripped != raw) yield stripped;

  // Strip "JSON" / "json" prefix label that lives outside the braces
  final labelStripped = stripped.replaceFirst(
    RegExp(r'^\s*(?:json|JSON)\s*[:\-]?\s*'),
    '',
  );
  if (labelStripped != stripped) yield labelStripped;

  // Smart quotes → straight quotes (fashion prose loves curly quotes)
  final quotesNormalized = labelStripped
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('‘', "'")
      .replaceAll('’', "'");
  if (quotesNormalized != labelStripped) yield quotesNormalized;

  // Strip trailing commas before `}` or `]` (a common Gemini glitch)
  final noTrailingCommas = quotesNormalized.replaceAll(
    RegExp(r',(\s*[}\]])'),
    r'$1',
  );
  if (noTrailingCommas != quotesNormalized) yield noTrailingCommas;
}
