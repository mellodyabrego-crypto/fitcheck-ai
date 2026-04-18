import 'package:flutter_dotenv/flutter_dotenv.dart';

// Compile-time values injected via `--dart-define`. Used for web production
// builds where .env is not served. Falls back to dotenv for local dev.
const _dartDefSupabaseUrl    = String.fromEnvironment('SUPABASE_URL');
const _dartDefSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _dartDefClaudeApiKey   = String.fromEnvironment('CLAUDE_API_KEY');
const _dartDefGeminiApiKey   = String.fromEnvironment('GEMINI_API_KEY');

String _pickEnv(String compileTime, String key) {
  if (compileTime.isNotEmpty) return compileTime;
  return dotenv.env[key] ?? '';
}

abstract class AppConstants {
  static String get supabaseUrl    => _pickEnv(_dartDefSupabaseUrl,    'SUPABASE_URL');
  static String get supabaseAnonKey => _pickEnv(_dartDefSupabaseAnonKey, 'SUPABASE_ANON_KEY');
  static String get claudeApiKey   => _pickEnv(_dartDefClaudeApiKey,   'CLAUDE_API_KEY');
  static String get geminiApiKey   => _pickEnv(_dartDefGeminiApiKey,   'GEMINI_API_KEY');

  static const String wardrobeBucket = 'wardrobe-images';
  static const String claudeModel = 'claude-sonnet-4-20250514';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String geminiModel = 'gemini-2.5-flash';

  // Free tier limits
  static const int freeWardrobeLimit = 20;
  static const int freeDailyOutfits = 3;
  static const int freeDailyFitChecks = 3;
}
