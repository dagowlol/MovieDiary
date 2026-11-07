import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie/features/movie_detail/movie_detail_screen.dart';
import 'package:movie/features/statistics/statistics_screen.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/widgets/movie_card.dart';

void main() {
  Movie inception({bool isWatched = false}) {
    return Movie(
      id: 1,
      title: 'Inception',
      director: 'Christopher Nolan',
      releaseYear: 2010,
      genre: 'Sci-Fi',
      rating: 4.5,
      isWatched: isWatched,
      review: 'Mind-bending masterpiece',
      watchedDate: isWatched ? '2024-01-15' : '',
    );
  }

  group('StatsSnapshot', () {
    test('returns zeros for an empty diary', () {
      final stats = StatsSnapshot.fromMovies(const []);

      expect(stats.total, 0);
      expect(stats.watched, 0);
      expect(stats.watchlist, 0);
      expect(stats.averageRating, 0);
      expect(stats.favoriteGenre, isNull);
    });

    test('counts watched vs watchlist and favorite genre', () {
      final stats = StatsSnapshot.fromMovies([
        inception(isWatched: true),
        Movie(
          id: 2,
          title: 'Dune',
          releaseYear: 2021,
          genre: 'Sci-Fi',
          rating: 5.0,
        ),
        Movie(
          id: 3,
          title: 'Whiplash',
          releaseYear: 2014,
          genre: 'Drama',
          rating: 4.0,
          isWatched: true,
        ),
      ]);

      expect(stats.total, 3);
      expect(stats.watched, 2);
      expect(stats.watchlist, 1);
      expect(stats.averageRating, closeTo(4.5, 0.01));
      expect(stats.favoriteGenre, 'Sci-Fi');
      expect(stats.genreCounts.first.count, 2);
    });
  });

  testWidgets('MovieDetailScreen shows movie info and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MovieDetailScreen(movie: inception()),
      ),
    );

    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('Christopher Nolan'), findsOneWidget);
    expect(find.text('2010'), findsOneWidget);
    expect(find.text('Sci-Fi'), findsOneWidget);
    expect(find.text('Mind-bending masterpiece'), findsOneWidget);
    expect(find.text('Mark as Watched'), findsOneWidget);
    expect(find.byKey(const Key('edit-movie')), findsOneWidget);
    expect(find.byKey(const Key('delete-movie')), findsOneWidget);
  });

  testWidgets('MovieDetailScreen delete dialog can be cancelled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MovieDetailScreen(movie: inception()),
      ),
    );

    await tester.tap(find.byKey(const Key('delete-movie')));
    await tester.pumpAndSettle();

    expect(find.text('Delete this movie?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this movie?'), findsNothing);
    expect(find.text('Inception'), findsOneWidget);
  });

  testWidgets('MovieCard exposes title and mark as watched action', (tester) async {
    var marked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieCard(
            movie: inception(),
            onMarkWatched: () => marked = true,
          ),
        ),
      ),
    );

    expect(find.text('Inception'), findsOneWidget);
    await tester.tap(find.text('Mark as watched'));
    expect(marked, isTrue);
  });
}
