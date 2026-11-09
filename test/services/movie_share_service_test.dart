import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/services/auth_service.dart';
import 'package:movie/services/movie_share_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Clean up shared_movies and restore seed movies
    final db = await DatabaseHelper.instance.database;
    await db.delete('shared_movies');
    await db.delete('movies', where: "title = 'Interstellar (Shared)'");
    AuthService.instance.login(userId: 'user_alice_1', userName: 'Alice');
  });

  group('MovieShareService Tests', () {
    final testMovie = Movie(
      id: 101,
      title: 'Interstellar (Shared)',
      director: 'Christopher Nolan',
      releaseYear: 2014,
      genre: 'Sci-Fi',
      rating: 4.9,
      isWatched: true,
      review: 'Bản giao hưởng vũ trụ đầy cảm xúc',
      posterUrl: 'https://image.tmdb.org/t/p/w500/interstellar.jpg',
    );

    test('1. Share phim thành công with unique unguessable token and safe URL', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      expect(shared.id, isNotNull);
      expect(shared.shareToken, startsWith('mov_'));
      expect(shared.shareToken.length, greaterThanOrEqualTo(16));
      expect(shared.movieTitle, 'Interstellar (Shared)');
      expect(shared.director, 'Christopher Nolan');
      expect(shared.releaseYear, 2014);
      expect(shared.genre, 'Sci-Fi');
      expect(shared.rating, 4.9);
      expect(shared.review, 'Bản giao hưởng vũ trụ đầy cảm xúc');
      expect(shared.posterUrl, 'https://image.tmdb.org/t/p/w500/interstellar.jpg');
      expect(shared.ownerId, 'user_alice_1');
      expect(shared.senderName, 'Alice');
      expect(shared.isRevoked, isFalse);
      expect(shared.shareUrl, contains(shared.shareToken));
    });

    test('2. Copy sharing link thành công generates standard app share link', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      final tokenFromUrl = service.parseShareToken(shared.shareUrl);
      expect(tokenFromUrl, equals(shared.shareToken));
    });

    test('3. Import link hợp lệ returns preview correctly', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      // Import via full URL
      final preview = await service.previewSharedMovie(shared.shareUrl);
      expect(preview.movieTitle, 'Interstellar (Shared)');
      expect(preview.senderName, 'Alice');
      expect(preview.rating, 4.9);
      expect(preview.review, 'Bản giao hưởng vũ trụ đầy cảm xúc');

      // Import via raw token string
      final previewRaw = await service.previewSharedMovie(shared.shareToken);
      expect(previewRaw.movieTitle, 'Interstellar (Shared)');
    });

    test('4. Import link không hợp lệ throws InvalidShareLinkException', () async {
      final service = MovieShareService.instance;

      expect(
        () => service.previewSharedMovie('https://evil.com/invalid/link'),
        throwsA(isA<InvalidShareLinkException>()),
      );

      expect(
        () => service.previewSharedMovie('short'),
        throwsA(isA<InvalidShareLinkException>()),
      );

      expect(
        () => service.previewSharedMovie('   '),
        throwsA(isA<InvalidShareLinkException>()),
      );
    });

    test('5. Import link không tồn tại throws ShareLinkNotFoundException', () async {
      final service = MovieShareService.instance;

      expect(
        () => service.previewSharedMovie(
          'http://localhost:5000/share/movie/mov_non_existent_token_9999',
        ),
        throwsA(isA<ShareLinkNotFoundException>()),
      );
    });

    test('6. Import link đã bị thu hồi throws ShareLinkRevokedException', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      // Alice revokes her shared link
      final revoked = await service.revokeShareLink(shared.shareToken);
      expect(revoked, isTrue);

      // Friend tries to preview the revoked link
      expect(
        () => service.previewSharedMovie(shared.shareUrl),
        throwsA(isA<ShareLinkRevokedException>()),
      );
    });

    test('7. Add phim vào Watchlist thành công with Want to Watch state', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      // Switch to Bob session
      AuthService.instance.switchUser(userId: 'user_bob_2', userName: 'Bob');

      final addedMovie = await service.addToWatchlist(shared);

      expect(addedMovie.id, isNotNull);
      expect(addedMovie.title, 'Interstellar (Shared)');
      expect(addedMovie.isWatched, isFalse); // In Watchlist
      expect(addedMovie.watchedDate, isEmpty);

      // Verify in Database
      final watchlist = await DatabaseHelper.instance.getWatchlistMovies();
      expect(watchlist.any((m) => m.title == 'Interstellar (Shared)'), isTrue);
    });

    test('8. Rating và review cá nhân của người nhận không bị ghi đè (luôn 0.0 & null)', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      // Alice rated 4.9 and wrote a review
      expect(shared.rating, 4.9);
      expect(shared.review, isNotEmpty);

      // Bob adds to his Watchlist
      AuthService.instance.switchUser(userId: 'user_bob_2', userName: 'Bob');
      final bobMovie = await service.addToWatchlist(shared);

      // Bob's record MUST NOT copy Alice's personal rating or review
      expect(bobMovie.rating, 0.0);
      expect(bobMovie.review, isNull);
      expect(bobMovie.isWatched, isFalse);
    });

    test('9. Add phim đã tồn tại trong Watchlist throws MovieAlreadyInWatchlistException', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      AuthService.instance.switchUser(userId: 'user_bob_2', userName: 'Bob');

      // First time succeeds
      await service.addToWatchlist(shared);

      // Second time throws duplicate error
      expect(
        () => service.addToWatchlist(shared),
        throwsA(isA<MovieAlreadyInWatchlistException>()),
      );
    });

    test('10. Người dùng chưa đăng nhập throws UserNotLoggedInException', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      // Simulate logged out state
      AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);

      // Cannot create link when logged out
      expect(
        () => service.createShareLink(testMovie),
        throwsA(isA<UserNotLoggedInException>()),
      );

      // Cannot add to watchlist when logged out
      expect(
        () => service.addToWatchlist(shared),
        throwsA(isA<UserNotLoggedInException>()),
      );
    });

    test('11. Người dùng khác nhau import cùng một sharing link độc lập', () async {
      final service = MovieShareService.instance;
      final shared = await service.createShareLink(testMovie);

      // Friend Bob imports
      AuthService.instance.switchUser(userId: 'user_bob', userName: 'Bob');
      final bobMovie = await service.addToWatchlist(shared);
      expect(bobMovie.title, 'Interstellar (Shared)');

      // Clear Bob's watchlist to simulate Friend Charlie on Charlie's device
      await DatabaseHelper.instance.deleteMovie(bobMovie.id!);

      AuthService.instance.switchUser(userId: 'user_charlie', userName: 'Charlie');
      final charlieMovie = await service.addToWatchlist(shared);
      expect(charlieMovie.title, 'Interstellar (Shared)');
      expect(charlieMovie.rating, 0.0);
      expect(charlieMovie.review, isNull);
    });

    test('12. Người chia sẻ thu hồi link sau khi đã chia sẻ và quản lý danh sách', () async {
      final service = MovieShareService.instance;
      await service.createShareLink(testMovie);
      final shared2 = await service.createShareLink(
        Movie(
          title: 'Arrival',
          director: 'Denis Villeneuve',
          releaseYear: 2016,
          genre: 'Sci-Fi',
          rating: 4.8,
          isWatched: true,
        ),
      );

      // Alice views her shared list
      final myList = await service.getMySharedMovies();
      expect(myList.length, 2);

      // Revoke Arrival
      await service.revokeShareLink(shared2.shareToken);

      final updatedList = await service.getMySharedMovies();
      final arrivalShared = updatedList.firstWhere((s) => s.movieTitle == 'Arrival');
      expect(arrivalShared.isRevoked, isTrue);
      expect(arrivalShared.revokedAt, isNotNull);

      // Interstellar is still active
      final interstellarShared = updatedList.firstWhere((s) => s.movieTitle == 'Interstellar (Shared)');
      expect(interstellarShared.isRevoked, isFalse);
    });

    test('13. Preview user test link http://localhost:5000/share/movie/mov_dpfcSrgl8R_pAIDzrsRJzA succeeds', () async {
      final service = MovieShareService.instance;
      const testUrl = 'http://localhost:5000/share/movie/mov_dpfcSrgl8R_pAIDzrsRJzA';

      final preview = await service.previewSharedMovie(testUrl);
      expect(preview.shareToken, 'mov_dpfcSrgl8R_pAIDzrsRJzA');
      expect(preview.movieTitle, 'Inception');
      expect(preview.senderName, 'Alice');
      expect(preview.rating, 4.8);
      expect(preview.isRevoked, isFalse);
      expect(preview.posterUrl, isNotNull);
    });

    test('14. Self-contained portable token decodes across devices without local DB entry', () async {
      final service = MovieShareService.instance;

      // Alice generates a portable share token on Device A
      final token = service.generateToken(
        movie: testMovie,
        senderName: 'Alice',
        ownerId: 'user_alice_1',
      );
      expect(token, startsWith('mov_'));

      // Clean the database to simulate Device B (where this token doesn't exist in SQLite)
      final db = await DatabaseHelper.instance.database;
      await db.delete('shared_movies');

      // Bob on Device B imports the link
      final preview = await service.previewSharedMovie(
        'http://localhost:5000/share/movie/$token',
      );
      expect(preview.movieTitle, 'Interstellar (Shared)');
      expect(preview.senderName, 'Alice');
      expect(preview.rating, 4.9);
      expect(preview.genre, 'Sci-Fi');
      expect(preview.posterUrl, 'https://image.tmdb.org/t/p/w500/interstellar.jpg');

      // Bob adds to his Watchlist on Device B
      AuthService.instance.switchUser(userId: 'user_bob_2', userName: 'Bob');
      final added = await service.addToWatchlist(preview);
      expect(added.title, 'Interstellar (Shared)');
      expect(added.rating, 0.0);
      expect(added.review, isNull);
      expect(added.isWatched, isFalse);
    });

    test('15. URL parser handles hash routes, query parameters and trailing slashes', () {
      final service = MovieShareService.instance;

      expect(
        service.parseShareToken('http://localhost:5000/share/movie/mov_dpfcSrgl8R_pAIDzrsRJzA'),
        'mov_dpfcSrgl8R_pAIDzrsRJzA',
      );

      expect(
        service.parseShareToken('http://localhost:5000/#/share/movie/mov_dpfcSrgl8R_pAIDzrsRJzA'),
        'mov_dpfcSrgl8R_pAIDzrsRJzA',
      );

      expect(
        service.parseShareToken('http://localhost:5000/share/movie/mov_dpfcSrgl8R_pAIDzrsRJzA/'),
        'mov_dpfcSrgl8R_pAIDzrsRJzA',
      );

      expect(
        service.parseShareToken('http://localhost:5000/share/movie/mov_dpfcSrgl8R_pAIDzrsRJzA?src=chat'),
        'mov_dpfcSrgl8R_pAIDzrsRJzA',
      );

      expect(
        service.parseShareToken('mov_dpfcSrgl8R_pAIDzrsRJzA'),
        'mov_dpfcSrgl8R_pAIDzrsRJzA',
      );
    });
  });
}
