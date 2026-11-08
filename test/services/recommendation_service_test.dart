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

    test('parseAndValidateResponse auto-repairs missing object brace and unwraps Gemini candidate envelope', () {
      final service = RecommendationService.instance;

      // The exact raw response format provided by the user with missing '}' after Arrival
      const rawUserEnvelope = '''
{
    "candidates": [
        {
            "content": {
                "parts": [
                    {
                        "text": "{\\n  \\"recommendations\\": [\\n    {\\n      \\"title\\": \\"Arrival\\",\\n      \\"year\\": 2016,\\n      \\"genre\\": [\\"Sci-Fi\\", \\"Drama\\"],\\n      \\"reason\\": \\"Với tình yêu của bạn dành cho những bộ phim Sci-Fi sâu sắc...\\",\\n      \\"matchScore\\": 96,\\n      \\"posterUrl\\": \\"https://image.tmdb.org/t/p/original/x2B7nQy98B5sO8TqK6f9L5N5nQ.jpg\\"\\n    ,\\n    {\\n      \\"title\\": \\"Blade Runner 2049\\",\\n      \\"year\\": 2017,\\n      \\"genre\\": [\\"Sci-Fi\\", \\"Neo-Noir\\"],\\n      \\"reason\\": \\"Nếu bạn yêu thích những bộ phim Sci-Fi có hình ảnh choáng ngợp...\\",\\n      \\"matchScore\\": 95,\\n      \\"posterUrl\\": \\"https://image.tmdb.org/t/p/original/gajva2L0rPYkEWj6rxKFMVp9ne5.jpg\\"\\n    },\\n    {\\n      \\"title\\": \\"Spider-Man: Into the Spider-Verse\\",\\n      \\"year\\": 2018,\\n      \\"genre\\": [\\"Animation\\", \\"Action\\", \\"Sci-Fi\\"],\\n      \\"reason\\": \\"Bạn đã đánh giá Spirited Away 5 sao...\\",\\n      \\"matchScore\\": 97,\\n      \\"posterUrl\\": \\"https://image.tmdb.org/t/p/original/iiZZdoQBPMJzdkfkTLpzgJ9NjQf.jpg\\"\\n    },\\n    {\\n      \\"title\\": \\"Memories of Murder\\",\\n      \\"year\\": 2003,\\n      \\"genre\\": [\\"Thriller\\", \\"Crime\\", \\"Drama\\"],\\n      \\"reason\\": \\"Với việc bạn cực kỳ yêu thích Parasite...\\",\\n      \\"matchScore\\": 93,\\n      \\"posterUrl\\": \\"https://image.tmdb.org/t/p/original/q2QYtq26X2s92k94w9oU0m3nFzS.jpg\\"\\n    },\\n    {\\n      \\"title\\": \\"Dune\\",\\n      \\"year\\": 2021,\\n      \\"genre\\": [\\"Sci-Fi\\", \\"Adventure\\", \\"Drama\\"],\\n      \\"reason\\": \\"Nếu bạn bị cuốn hút bởi những hành trình không gian hoành tráng...\\",\\n      \\"matchScore\\": 94,\\n      \\"posterUrl\\": \\"https://image.tmdb.org/t/p/original/d8yswS2Sjt9C3Gk7I7E1v3y827h.jpg\\"\\n    }\\n  ]\\n}"
                    }
                ],
                "role": "model"
            },
            "finishReason": "STOP",
            "index": 0
        }
    ],
    "modelVersion": "gemini-2.5-flash"
}
''';

      final recommendations = service.parseAndValidateResponse(
        rawUserEnvelope,
        watchedMovies: testWatchedMovies,
      );

      expect(recommendations.length, 5);

      expect(recommendations[0].title, 'Arrival');
      expect(recommendations[0].year, 2016);
      expect(recommendations[0].matchScore, 96);
      expect(
        recommendations[0].posterUrl,
        'https://image.tmdb.org/t/p/original/x2B7nQy98B5sO8TqK6f9L5N5nQ.jpg',
      );

      expect(recommendations[1].title, 'Blade Runner 2049');
      expect(recommendations[1].year, 2017);
      expect(recommendations[1].matchScore, 95);

      expect(recommendations[2].title, 'Spider-Man: Into the Spider-Verse');
      expect(recommendations[2].year, 2018);
      expect(recommendations[2].matchScore, 97);

      expect(recommendations[3].title, 'Memories of Murder');
      expect(recommendations[3].year, 2003);
      expect(recommendations[3].matchScore, 93);

      expect(recommendations[4].title, 'Dune');
      expect(recommendations[4].year, 2021);
      expect(recommendations[4].matchScore, 94);
    });
  });
}
