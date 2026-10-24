import 'package:flutter_test/flutter_test.dart';
import 'package:movie/models/movie.dart';

void main() {
  group('Movie Model Tests', () {
    test('toMap converts Movie to expected Map', () {
      final movie = Movie(
        id: 1,
        title: 'Inception',
        director: 'Christopher Nolan',
        releaseYear: 2010,
        genre: 'Sci-Fi',
        rating: 4.8,
        isWatched: true,
        review: 'Mind-bending masterpiece',
        watchedDate: '2024-01-15',
      );

      final map = movie.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Inception');
      expect(map['director'], 'Christopher Nolan');
      expect(map['release_year'], 2010);
      expect(map['genre'], 'Sci-Fi');
      expect(map['rating'], 4.8);
      expect(map['is_watched'], 1);
      expect(map['review'], 'Mind-bending masterpiece');
      expect(map['watched_date'], '2024-01-15');
    });

    test('fromMap constructs Movie correctly from SQLite map', () {
      final map = {
        'id': 2,
        'title': 'Interstellar',
        'director': 'Christopher Nolan',
        'release_year': 2014,
        'genre': 'Sci-Fi',
        'rating': 5.0,
        'is_watched': 0,
        'review': null,
        'watched_date': '',
      };

      final movie = Movie.fromMap(map);

      expect(movie.id, 2);
      expect(movie.title, 'Interstellar');
      expect(movie.director, 'Christopher Nolan');
      expect(movie.releaseYear, 2014);
      expect(movie.genre, 'Sci-Fi');
      expect(movie.rating, 5.0);
      expect(movie.isWatched, false);
      expect(movie.review, isNull);
      expect(movie.watchedDate, '');
    });

    test('copyWith updates fields correctly without mutating original', () {
      final movie = Movie(
        id: 1,
        title: 'Original Title',
        releaseYear: 2020,
        genre: 'Action',
      );

      final updated = movie.copyWith(
        title: 'Updated Title',
        rating: 4.5,
        isWatched: true,
      );

      expect(updated.id, 1);
      expect(updated.title, 'Updated Title');
      expect(updated.rating, 4.5);
      expect(updated.isWatched, true);
      expect(updated.genre, 'Action');
      expect(movie.title, 'Original Title');
      expect(movie.isWatched, false);
    });
  });
}

