import 'package:flutter_test/flutter_test.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/models/movie_recommendation.dart';
import 'package:movie/services/ai_client.dart';
import 'package:movie/services/recommendation_service.dart';

void main() {
  group('RecommendationService Tests', () {
    final testWatchedMovies = [
      Movie(
        id: 1,
        title: 'Inception',
        director: 'Christopher Nolan',
        releaseYear: 2010,
        genre: 'Sci-Fi',
        rating: 4.8,
        isWatched: true,
        review: 'Mind-bending dream heist',
      ),
      Movie(
        id: 2,
        title: 'Interstellar',
        director: 'Christopher Nolan',
        releaseYear: 2014,
        genre: 'Sci-Fi',
        rating: 4.9,
        isWatched: true,
        review: 'Emotional masterpiece',
      ),
      Movie(
        id: 3,
        title: 'Spirited Away',
        director: 'Hayao Miyazaki',
        releaseYear: 2001,
        genre: 'Animation',
        rating: 5.0,
        isWatched: true,
      ),
    ];

    test('buildPrompt dynamically constructs prompt with user history and negative constraint', () {
      final service = RecommendationService.instance;
      final prompt = service.buildPrompt(testWatchedMovies);

      // Verify user's actual watched movies are included
      expect(prompt, contains('Inception'));
      expect(prompt, contains('Interstellar'));
      expect(prompt, contains('Spirited Away'));
      expect(prompt, contains('Sci-Fi'));

      // Verify reviews are included
      expect(prompt, contains('Mind-bending dream heist'));

      // Verify negative rule constraint
      expect(
        prompt,
        contains('DO NOT recommend any movie that the user has already watched'),
      );
      expect(prompt, contains('"Inception"'));
      expect(prompt, contains('"Interstellar"'));
      expect(prompt, contains('"Spirited Away"'));
    });

    test('parseAndValidateResponse successfully parses JSON even with markdown fences', () {
      final service = RecommendationService.instance;

      const aiOutputWithMarkdown = '''
Here are your personalized recommendations:
```json
{
  "recommendations": [
    {
      "title": "Arrival",
      "year": 2016,
      "genre": ["Sci-Fi", "Drama"],
      "reason": "Vì bạn thích phim Sci-Fi triết lý và sâu sắc như Interstellar.",
      "matchScore": 95,
      "posterUrl": "https://example.com/arrival.jpg"
    },
    {
      "title": "Blade Runner 2049",
      "year": 2017,
      "genre": ["Sci-Fi", "Mystery"],
      "reason": "Phù hợp với sở thích Sci-Fi và điện ảnh của Christopher Nolan.",
      "matchScore": 92
    }
  ]
}
```
Hope you enjoy these!
''';

      final recommendations = service.parseAndValidateResponse(
        aiOutputWithMarkdown,
        watchedMovies: testWatchedMovies,
      );

      expect(recommendations.length, 2);
      expect(recommendations[0].title, 'Arrival');
      expect(recommendations[0].year, 2016);
      expect(recommendations[0].genre, ['Sci-Fi', 'Drama']);
      expect(recommendations[0].matchScore, 95);
      expect(recommendations[0].posterUrl, 'https://example.com/arrival.jpg');
      expect(recommendations[0].isFromFallback, isFalse);

      expect(recommendations[1].title, 'Blade Runner 2049');
      expect(recommendations[1].year, 2017);
      expect(recommendations[1].matchScore, 92);
      expect(recommendations[1].posterUrl, isNull);
    });

    test('parseAndValidateResponse filters already watched movies and duplicates', () {
      final service = RecommendationService.instance;

      const rawAiResponse = '''
{
  "recommendations": [
    {
      "title": "Inception",
      "year": 2010,
      "genre": ["Sci-Fi"],
      "reason": "You love Inception!",
      "matchScore": 99
    },
    {
      "title": "inception  ",
      "year": 2010,
      "genre": ["Sci-Fi"],
      "reason": "Duplicate title test",
      "matchScore": 99
    },
    {
      "title": "Dune",
      "year": 2021,
      "genre": ["Sci-Fi", "Adventure"],
      "reason": "Epic space world-building.",
      "matchScore": 93
    },
    {
      "title": "Dune",
      "year": 2021,
      "genre": ["Sci-Fi"],
      "reason": "Duplicate Dune",
      "matchScore": 93
    }
  ]
}
''';

      final recommendations = service.parseAndValidateResponse(
        rawAiResponse,
        watchedMovies: testWatchedMovies,
      );

      // Inception is already in testWatchedMovies -> filtered out!
      // Dune is duplicated -> only one Dune remains!
      expect(recommendations.length, 1);
      expect(recommendations.first.title, 'Dune');
      expect(recommendations.first.year, 2021);
    });

    test('getRecommendations returns success when AI Client produces valid output', () async {
      final service = RecommendationService.instance;

      service.configure(
        client: MockAiClient(
          onGenerate: (prompt) async => '''
{
  "recommendations": [
    {
      "title": "Contact",
      "year": 1997,
      "genre": ["Sci-Fi", "Drama"],
      "reason": "Bộ phim khám phá vũ trụ tuyệt đỉnh.",
      "matchScore": 91
    }
  ]
}
''',
        ),
      );

      final result = await service.getRecommendations(forceRefresh: true);

      expect(result.status, RecommendationStatus.success);
      expect(result.isFallback, isFalse);
      expect(result.recommendations.length, 1);
      expect(result.recommendations.first.title, 'Contact');
    });

    test('getRecommendations switches to fallback on AI failure without hardcoding movies', () async {
      final service = RecommendationService.instance;

      // Simulate network / server / parse failure
      service.configure(
        client: MockAiClient(
          onGenerate: (prompt) async => throw Exception('API Timeout (504)'),
        ),
      );

      final result = await service.getRecommendations(forceRefresh: true);

      expect(result.status, RecommendationStatus.fallback);
      expect(result.isFallback, isTrue);
      expect(result.message, contains('Không thể kết nối AI'));
      expect(result.recommendations, isNotEmpty);

      // Verify fallback items are derived from user's own high-rated watched movies
      for (final rec in result.recommendations) {
        expect(rec.isFromFallback, isTrue);
        expect(rec.reason, contains('Phim bạn đã chấm'));
      }
    });
  });
}
