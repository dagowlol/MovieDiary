import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:movie/database/database_helper.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/models/movie_recommendation.dart';
import 'package:movie/services/ai_client.dart';

class RecommendationService {
  // Singleton pattern
  static final RecommendationService instance = RecommendationService._init();

  RecommendationService._init();

  // Configurable credentials (read from environment by default, can be modified at runtime)
  String _apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: String.fromEnvironment(
      'AI_API_KEY',
      defaultValue: '',
    ),
  );
  String _provider = const String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'gemini',
  );
  String _baseUrl = const String.fromEnvironment(
    'GEMINI_API_URL',
    defaultValue: String.fromEnvironment(
      'AI_BASE_URL',
      defaultValue: 'https://generativelanguage.googleapis.com',
    ),
  );
  String _model = const String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  AiClient? _customClient;
  RecommendationResult? _cachedResult;

  String get apiKey => _apiKey;
  String get provider => _provider;
  String get baseUrl => _baseUrl;
  String get model => _model;
  bool get hasApiKey => _apiKey.trim().isNotEmpty || _customClient != null;

  /// Configure AI settings at runtime (e.g. from UI settings or testing)
  void configure({
    String? apiKey,
    String? provider,
    String? baseUrl,
    String? model,
    AiClient? client,
  }) {
    if (apiKey != null) _apiKey = apiKey.trim();
    if (provider != null) _provider = provider.trim().toLowerCase();
    if (baseUrl != null) _baseUrl = baseUrl.trim();
    if (model != null) _model = model.trim();
    if (client != null) _customClient = client;
    _cachedResult = null; // Invalidate cache on re-configuration
  }

  /// Factory to obtain active AI client
  AiClient _getClient() {
    if (_customClient != null) return _customClient!;

    if (_provider == 'openai') {
      return OpenAiClient(apiKey: _apiKey, baseUrl: _baseUrl, model: _model);
    }
    // Default to Gemini
    return GeminiAiClient(apiKey: _apiKey, baseUrl: _baseUrl, model: _model);
  }

  /// Clear in-memory recommendation cache
  void clearCache() {
    _cachedResult = null;
  }

  /// Main entry point: UI only calls this method
  Future<RecommendationResult> getRecommendations({
    bool forceRefresh = false,
  }) async {
    // Only return cache if it was an actual AI success
    if (!forceRefresh &&
        _cachedResult != null &&
        _cachedResult!.status == RecommendationStatus.success) {
      return _cachedResult!;
    }

    // Step 1: Collect User Watch History from DatabaseHelper
    final allMovies = await DatabaseHelper.instance.getAllMovies();
    final watchedMovies = allMovies.where((m) => m.isWatched).toList();

    // Step 2: Empty history check
    if (watchedMovies.isEmpty) {
      final result = RecommendationResult.emptyHistory();
      _cachedResult = result;
      return result;
    }

    // Step 3: Check if AI API is available
    if (!hasApiKey) {
      return _buildFallback(
        watchedMovies,
        'Chưa cấu hình API Key cho AI. Đang hiển thị gợi ý xem lại từ phim bạn yêu thích.',
      );
    }

    // Step 4: Construct dynamic prompt & call AI
    try {
      final prompt = buildPrompt(watchedMovies);
      final client = _getClient();
      debugPrint('RecommendationService: Calling AI model ($_model)...');
      final rawResponse = await client.generateContent(prompt);
      debugPrint(
        'RecommendationService: Received response (${rawResponse.length} chars)',
      );

      // Step 5: Validate and parse AI response
      final validated = parseAndValidateResponse(
        rawResponse,
        watchedMovies: watchedMovies,
      );

      if (validated.isEmpty) {
        throw const FormatException(
          'AI returned no valid new recommendations.',
        );
      }

      debugPrint(
        'RecommendationService: Successfully validated ${validated.length} recommendations.',
      );
      final result = RecommendationResult.success(validated);
      _cachedResult = result;
      return result;
    } catch (e, st) {
      debugPrint('RecommendationService: AI call failed: $e');
      debugPrint('RecommendationService stack: $st');
      // Step 6: Fallback Logic on any failure (DO NOT cache fallback so retry works)
      return _buildFallback(
        watchedMovies,
        'Không thể kết nối AI (${e.toString()}). Đang hiển thị gợi ý xem lại từ nhật ký của bạn.',
      );
    }
  }

  /// Builds a dynamic prompt strictly tailored to user's personal diary
  String buildPrompt(List<Movie> watchedMovies) {
    // Collect user preference insights
    final genreScores = <String, double>{};
    for (final m in watchedMovies) {
      if (m.genre.isNotEmpty) {
        genreScores[m.genre] = (genreScores[m.genre] ?? 0.0) + m.rating;
      }
    }

    final topGenres = genreScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredGenreList = topGenres.take(4).map((e) => e.key).join(', ');

    // Format watched history
    final historyBuffer = StringBuffer();
    for (final m in watchedMovies) {
      historyBuffer.write(
        '- ${m.title} (${m.releaseYear}) · Genre: ${m.genre}',
      );
      if (m.rating > 0) {
        historyBuffer.write(' · Rating: ${m.rating.toStringAsFixed(1)}/5.0');
      }
      if (m.review != null && m.review!.trim().isNotEmpty) {
        historyBuffer.write(' · Review: "${m.review!.trim()}"');
      }
      historyBuffer.writeln();
    }

    // List of watched titles for strict negative constraint
    final watchedTitles = watchedMovies.map((m) => '"${m.title}"').join(', ');

    return '''
You are an expert movie recommendation assistant.

Analyze this user's personal movie watching diary and taste preferences.

=== USER WATCH HISTORY ===
$historyBuffer

=== USER TASTE PROFILE ===
- Preferred genres: ${preferredGenreList.isNotEmpty ? preferredGenreList : 'Various'}
- Total movies watched: ${watchedMovies.length}

=== STRICT REQUIREMENTS ===
1. DO NOT recommend any movie that the user has already watched: [$watchedTitles].
2. Recommend 4 to 6 fresh, diverse, high-quality movies that match their tastes.
3. For each recommended movie, explain specifically in Vietnamese why the user would enjoy it (field "reason").
4. Provide a "matchScore" integer between 75 and 98 based on user history.
5. If you know a valid public poster URL (e.g. from TMDB or Wikimedia), provide it in "posterUrl"; otherwise use null.
6. Ensure the JSON is 100% syntactically valid with proper closing braces '}' for every object in the list.
7. Return ONLY valid JSON matching this exact structure:
{
  "recommendations": [
    {
      "title": "Movie Title",
      "year": 2024,
      "genre": ["Sci-Fi", "Drama"],
      "reason": "Vì bạn rất thích các bộ phim Sci-Fi có chiều sâu và ý tưởng độc đáo...",
      "matchScore": 94,
      "posterUrl": null
    }
  ]
}
''';
  }

  /// Parses and validates the AI JSON output, removing duplicates & watched movies
  List<MovieRecommendation> parseAndValidateResponse(
    String raw, {
    required List<Movie> watchedMovies,
  }) {
    final cleanedJson = _extractJson(raw);
    dynamic decoded;

    try {
      decoded = jsonDecode(cleanedJson);
    } catch (_) {
      // Auto-repair common LLM JSON syntax issues (missing braces, trailing commas, truncated output)
      final repaired = _repairJson(cleanedJson);
      decoded = jsonDecode(repaired);
    }

    // Extract the recommendation list from Map or direct List
    List? list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      // Handle full Gemini API response envelopes (candidates -> content -> parts -> text)
      if (decoded.containsKey('candidates')) {
        final candidates = decoded['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final textParts = parts
                .whereType<Map>()
                .where((p) => p['thought'] != true)
                .map((p) => (p['text'] ?? '').toString())
                .where((t) => t.trim().isNotEmpty)
                .toList();
            final innerText = textParts.join('');
            if (innerText.trim().isNotEmpty) {
              return parseAndValidateResponse(
                innerText,
                watchedMovies: watchedMovies,
              );
            }
          }
        }
      }

      // Handle OpenAI API response envelopes (choices -> message -> content)
      if (decoded.containsKey('choices')) {
        final choices = decoded['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return parseAndValidateResponse(
              content,
              watchedMovies: watchedMovies,
            );
          }
        }
      }

      if (decoded['recommendations'] is List) {
        list = decoded['recommendations'] as List;
      } else if (decoded['movies'] is List) {
        list = decoded['movies'] as List;
      } else if (decoded['data'] is List) {
        list = decoded['data'] as List;
      } else if (decoded.containsKey('title')) {
        list = [decoded];
      }
    }

    if (list == null) {
      throw const FormatException(
        'Key "recommendations" missing or response is not a valid list.',
      );
    }

    final watchedNormalized = watchedMovies
        .map((m) => _normalizeTitle(m.title))
        .toSet();

    final results = <MovieRecommendation>[];
    final seenTitles = <String>{};

    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;

      final title = (item['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;

      final normalized = _normalizeTitle(title);

      // Filter already watched movies
      if (watchedNormalized.contains(normalized)) {
        continue;
      }

      // Filter duplicate recommendations
      if (seenTitles.contains(normalized)) {
        continue;
      }
      seenTitles.add(normalized);

      results.add(MovieRecommendation.fromJson(item));
    }

    return results;
  }

  /// Self-healing JSON fixer for common LLM syntax flaws
  String _repairJson(String raw) {
    var fixed = raw.trim();

    // 1. Missing closing brace '}' before comma and next object in array:
    // e.g. "posterUrl": "https://..."\n    ,\n    {
    fixed = fixed.replaceAllMapped(
      RegExp(r'([^}\]\s])\s*,\s*\{'),
      (match) => '${match.group(1)}},\n    {',
    );

    // 2. Trailing comma before ']' or '}': e.g. ", ]" or ", }"
    fixed = fixed.replaceAll(RegExp(r',\s*([\]}])'), r'$1');

    // 3. Balance unclosed quotes, brackets, or braces (e.g. truncated response)
    int openBraces = 0;
    int openBrackets = 0;
    bool inString = false;
    bool isEscaped = false;

    for (int i = 0; i < fixed.length; i++) {
      final char = fixed[i];
      if (isEscaped) {
        isEscaped = false;
        continue;
      }
      if (char == r'\') {
        isEscaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (!inString) {
        if (char == '{') openBraces++;
        if (char == '}') openBraces--;
        if (char == '[') openBrackets++;
        if (char == ']') openBrackets--;
      }
    }

    if (inString) {
      fixed += '"';
    }
    while (openBrackets > 0) {
      fixed += ']';
      openBrackets--;
    }
    while (openBraces > 0) {
      fixed += '}';
      openBraces--;
    }

    return fixed;
  }

  /// Fallback logic: utilizes only user's own diary entries (NO hardcoded movie catalog)
  RecommendationResult _buildFallback(
    List<Movie> watchedMovies,
    String reason,
  ) {
    // 1. Pick movies user rated high (rating >= 4.0), sorted descending
    final highRated = watchedMovies.where((m) => m.rating >= 4.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    final sourceList = highRated.isNotEmpty
        ? highRated.take(4).toList()
        : watchedMovies.take(3).toList();

    if (sourceList.isEmpty) {
      return RecommendationResult.error(
        'Chưa thể tạo gợi ý phim mới. Vui lòng thử lại sau.',
      );
    }

    final recommendations = sourceList.map((m) {
      final score = (m.rating * 20).round().clamp(75, 100);
      return MovieRecommendation(
        title: m.title,
        year: m.releaseYear,
        genre: m.genre.isNotEmpty ? [m.genre] : ['Movie'],
        reason: m.rating > 0
            ? 'Phim bạn đã chấm ${m.rating.toStringAsFixed(1)}⭐ - Một tác phẩm xuất sắc rất đáng để bạn thưởng thức lại.'
            : 'Phim bạn đã lưu trong nhật ký cá nhân.',
        matchScore: score,
        posterUrl: m.posterUrl,
        isFromFallback: true,
      );
    }).toList();

    return RecommendationResult.fallback(recommendations, reason: reason);
  }

  /// Utility to strip markdown fences (```json ... ```) or find JSON object
  String _extractJson(String raw) {
    var text = raw.trim();
    final codeBlockRegex = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    );
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) {
      text = match.group(1)!.trim();
    } else {
      // Find outermost '{' ... '}' or '[' ... ']'
      final startBrace = text.indexOf('{');
      final startBracket = text.indexOf('[');

      int start = -1;
      int end = -1;

      if (startBrace != -1 &&
          (startBracket == -1 || startBrace < startBracket)) {
        start = startBrace;
        end = text.lastIndexOf('}');
      } else if (startBracket != -1) {
        start = startBracket;
        end = text.lastIndexOf(']');
      }

      if (start != -1 && end != -1 && end > start) {
        text = text.substring(start, end + 1);
      }
    }
    return text;
  }

  /// Normalizes a movie title for reliable comparison
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
