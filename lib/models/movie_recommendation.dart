class MovieRecommendation {
  final String title;
  final int year;
  final List<String> genre;
  final String reason;
  final int matchScore;
  final String? posterUrl;
  final bool isFromFallback;

  const MovieRecommendation({
    required this.title,
    required this.year,
    required this.genre,
    required this.reason,
    required this.matchScore,
    this.posterUrl,
    this.isFromFallback = false,
  });

  factory MovieRecommendation.fromJson(
    Map<String, dynamic> json, {
    bool isFromFallback = false,
  }) {
    // Defensive parsing for release year
    int parsedYear = 0;
    if (json['year'] != null) {
      parsedYear = int.tryParse(json['year'].toString()) ?? 0;
    }

    // Defensive parsing for genre list
    List<String> parsedGenre = [];
    final rawGenre = json['genre'];
    if (rawGenre is List) {
      parsedGenre = rawGenre
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } else if (rawGenre is String) {
      parsedGenre = rawGenre
          .split(RegExp(r'[,/•|]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    // Defensive parsing for match score (0 - 100)
    int parsedScore = 90;
    if (json['matchScore'] != null) {
      parsedScore = int.tryParse(json['matchScore'].toString()) ?? 90;
    }

    // Defensive parsing for poster URL
    String? poster = json['posterUrl'] as String?;
    if (poster != null && poster.trim().isEmpty) {
      poster = null;
    }

    return MovieRecommendation(
      title: (json['title'] ?? '').toString().trim(),
      year: parsedYear,
      genre: parsedGenre,
      reason: (json['reason'] ?? '').toString().trim(),
      matchScore: parsedScore.clamp(0, 100),
      posterUrl: poster,
      isFromFallback: isFromFallback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'year': year,
      'genre': genre,
      'reason': reason,
      'matchScore': matchScore,
      'posterUrl': posterUrl,
      'isFromFallback': isFromFallback,
    };
  }
}

enum RecommendationStatus {
  idle,
  loading,
  emptyHistory,
  success,
  fallback,
  error,
}

class RecommendationResult {
  final List<MovieRecommendation> recommendations;
  final RecommendationStatus status;
  final bool isFallback;
  final String? message;

  const RecommendationResult({
    required this.recommendations,
    required this.status,
    this.isFallback = false,
    this.message,
  });

  factory RecommendationResult.success(List<MovieRecommendation> list) {
    return RecommendationResult(
      recommendations: list,
      status: RecommendationStatus.success,
      isFallback: false,
    );
  }

  factory RecommendationResult.fallback(
    List<MovieRecommendation> list, {
    String? reason,
  }) {
    return RecommendationResult(
      recommendations: list,
      status: RecommendationStatus.fallback,
      isFallback: true,
      message: reason,
    );
  }

  factory RecommendationResult.emptyHistory() {
    return const RecommendationResult(
      recommendations: [],
      status: RecommendationStatus.emptyHistory,
      message:
          'Chưa đủ dữ liệu. Hãy thêm một vài bộ phim bạn đã xem để AI có thể hiểu sở thích của bạn.',
    );
  }

  factory RecommendationResult.error(String message) {
    return RecommendationResult(
      recommendations: const [],
      status: RecommendationStatus.error,
      message: message,
    );
  }
}
