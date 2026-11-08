import 'package:flutter_test/flutter_test.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/utils/constants.dart';

void main() {
  group('DatabaseHelper Seed Data Tests', () {
    test('initialMovies contains rich demo data with both watched and unwatched', () {
      final movies = DatabaseHelper.initialMovies;
      expect(movies, isNotEmpty);
      expect(movies.length, greaterThanOrEqualTo(5));

      final watched = movies.where((m) => m.isWatched).toList();
      final watchlist = movies.where((m) => !m.isWatched).toList();

      expect(watched, isNotEmpty, reason: 'Must have watched movies for Stats');
      expect(watchlist, isNotEmpty, reason: 'Must have watchlist movies');
    });

    test('all seed movies have valid genres and fields', () {
      final validGenres = Constants.movieGenres.toSet();

      for (final movie in DatabaseHelper.initialMovies) {
        expect(movie.title.trim(), isNotEmpty);
        expect(movie.releaseYear, greaterThan(1900));
        expect(
          validGenres.contains(movie.genre),
          isTrue,
          reason: 'Genre ${movie.genre} should be in Constants.movieGenres',
        );

        if (movie.isWatched) {
          expect(movie.rating, greaterThan(0.0));
          expect(movie.watchedDate, isNotEmpty);
        }

        // Verify SQLite serialization works for all seed movies
        final map = movie.toMap();
        expect(map[Constants.colTitle], movie.title);
        expect(map[Constants.colGenre], movie.genre);
      }
    });
  });
}
