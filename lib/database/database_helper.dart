import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/models/shared_movie.dart';
import 'package:movie/utils/constants.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static void ensureInitialized() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    ensureInitialized();
    _database = await _initDB(Constants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    final db = await openDatabase(
      path,
      version: Constants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA busy_timeout = 5000');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
    await _seedIfEmpty(db);
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${Constants.tableMovies} (
        ${Constants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${Constants.colTitle} TEXT NOT NULL,
        ${Constants.colDirector} TEXT,
        ${Constants.colReleaseYear} INTEGER NOT NULL,
        ${Constants.colGenre} TEXT NOT NULL,
        ${Constants.colRating} REAL NOT NULL DEFAULT 0.0,
        ${Constants.colIsWatched} INTEGER NOT NULL DEFAULT 0,
        ${Constants.colReview} TEXT,
        ${Constants.colWatchedDate} TEXT,
        ${Constants.colPosterUrl} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Constants.tableSharedMovies} (
        ${Constants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${Constants.colShareToken} TEXT UNIQUE NOT NULL,
        ${Constants.colOwnerId} TEXT NOT NULL,
        ${Constants.colSenderName} TEXT NOT NULL,
        ${Constants.colMovieTitle} TEXT NOT NULL,
        ${Constants.colDirector} TEXT,
        ${Constants.colReleaseYear} INTEGER NOT NULL,
        ${Constants.colGenre} TEXT NOT NULL,
        ${Constants.colRating} REAL NOT NULL DEFAULT 0.0,
        ${Constants.colReview} TEXT,
        ${Constants.colPosterUrl} TEXT,
        ${Constants.colCreatedAt} TEXT NOT NULL,
        ${Constants.colRevokedAt} TEXT,
        ${Constants.colIsRevoked} INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${Constants.tableMovies} ADD COLUMN ${Constants.colPosterUrl} TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${Constants.tableSharedMovies} (
          ${Constants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${Constants.colShareToken} TEXT UNIQUE NOT NULL,
          ${Constants.colOwnerId} TEXT NOT NULL,
          ${Constants.colSenderName} TEXT NOT NULL,
          ${Constants.colMovieTitle} TEXT NOT NULL,
          ${Constants.colDirector} TEXT,
          ${Constants.colReleaseYear} INTEGER NOT NULL,
          ${Constants.colGenre} TEXT NOT NULL,
          ${Constants.colRating} REAL NOT NULL DEFAULT 0.0,
          ${Constants.colReview} TEXT,
          ${Constants.colPosterUrl} TEXT,
          ${Constants.colCreatedAt} TEXT NOT NULL,
          ${Constants.colRevokedAt} TEXT,
          ${Constants.colIsRevoked} INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  /// Initial mock movies used to seed the database on first run
  static final List<Movie> initialMovies = [
    Movie(
      title: 'Inception',
      director: 'Christopher Nolan',
      releaseYear: 2010,
      genre: 'Sci-Fi',
      rating: 4.8,
      isWatched: true,
      review:
          'A mind-bending masterpiece with brilliant storytelling and stunning visuals.',
      watchedDate: '2024-01-15',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/ljsZTbVsrQSqZgWeep2B1QiDKuh.jpg',
    ),
    Movie(
      title: 'The Dark Knight',
      director: 'Christopher Nolan',
      releaseYear: 2008,
      genre: 'Action',
      rating: 4.9,
      isWatched: true,
      review:
          "Heath Ledger's iconic performance as the Joker makes this the definitive comic book movie.",
      watchedDate: '2024-02-10',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
    ),
    Movie(
      title: 'Spirited Away',
      director: 'Hayao Miyazaki',
      releaseYear: 2001,
      genre: 'Animation',
      rating: 5.0,
      isWatched: true,
      review:
          'An enchanting and timeless Ghibli masterpiece full of imagination and heart.',
      watchedDate: '2024-03-05',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg',
    ),
    Movie(
      title: 'Interstellar',
      director: 'Christopher Nolan',
      releaseYear: 2014,
      genre: 'Sci-Fi',
      rating: 4.7,
      isWatched: true,
      review:
          'An emotionally resonant journey across space and time with an unforgettable score.',
      watchedDate: '2024-03-22',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
    ),
    Movie(
      title: 'Parasite',
      director: 'Bong Joon-ho',
      releaseYear: 2019,
      genre: 'Thriller',
      rating: 4.6,
      isWatched: true,
      review:
          'Pitch-perfect social satire with unforgettable twists and razor-sharp direction.',
      watchedDate: '2024-04-18',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg',
    ),
    Movie(
      title: 'Dune: Part Two',
      director: 'Denis Villeneuve',
      releaseYear: 2024,
      genre: 'Sci-Fi',
      rating: 0.0,
      isWatched: false,
      review: null,
      watchedDate: '',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
    ),
    Movie(
      title: 'The Grand Budapest Hotel',
      director: 'Wes Anderson',
      releaseYear: 2014,
      genre: 'Comedy',
      rating: 0.0,
      isWatched: false,
      review: null,
      watchedDate: '',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/eWdyYQreja6JGCzqHWX9NZkt5BW.jpg',
    ),
    Movie(
      title: 'Oppenheimer',
      director: 'Christopher Nolan',
      releaseYear: 2023,
      genre: 'Drama',
      rating: 0.0,
      isWatched: false,
      review: null,
      watchedDate: '',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    ),
  ];

  /// Seeds initial movie data if the movies table is currently empty
  Future<void> _seedIfEmpty(Database db) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${Constants.tableMovies}',
    );
    final count = (result.isNotEmpty ? result.first['count'] as num? : null)?.toInt() ?? 0;
    if (count == 0) {
      await seedInitialData(db);
    } else {
      // Ensure sample shared movie exists for demo / testing
      final sharedCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${Constants.tableSharedMovies}',
      );
      final sharedCount = (sharedCountResult.isNotEmpty
              ? sharedCountResult.first['count'] as num?
              : null)
          ?.toInt() ?? 0;
      if (sharedCount == 0) {
        await db.insert(
          Constants.tableSharedMovies,
          const SharedMovie(
            shareToken: 'mov_dpfcSrgl8R_pAIDzrsRJzA',
            ownerId: 'user_alice_1',
            senderName: 'Alice',
            movieTitle: 'Inception',
            director: 'Christopher Nolan',
            releaseYear: 2010,
            genre: 'Sci-Fi',
            rating: 4.8,
            review:
                'Phim cực hay, kịch bản xoắn não và kỹ xảo đỉnh cao. Nhất định phải xem!',
            posterUrl:
                'https://image.tmdb.org/t/p/w500/ljsZTbVsrQSqZgWeep2B1QiDKuh.jpg',
            createdAt: '2026-11-08T20:00:00.000000',
            isRevoked: false,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// Bulk inserts the initial seed movies into the database
  Future<void> seedInitialData([Database? db]) async {
    final targetDb = db ?? await database;
    final batch = targetDb.batch();
    for (final movie in initialMovies) {
      batch.insert(Constants.tableMovies, movie.toMap());
    }
    // Seed initial sample shared movie
    batch.insert(
      Constants.tableSharedMovies,
      const SharedMovie(
        shareToken: 'mov_dpfcSrgl8R_pAIDzrsRJzA',
        ownerId: 'user_alice_1',
        senderName: 'Alice',
        movieTitle: 'Inception',
        director: 'Christopher Nolan',
        releaseYear: 2010,
        genre: 'Sci-Fi',
        rating: 4.8,
        review:
            'Phim cực hay, kịch bản xoắn não và kỹ xảo đỉnh cao. Nhất định phải xem!',
        posterUrl:
            'https://image.tmdb.org/t/p/w500/ljsZTbVsrQSqZgWeep2B1QiDKuh.jpg',
        createdAt: '2026-11-08T20:00:00.000000',
        isRevoked: false,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await batch.commit(noResult: true);
  }

  // CREATE
  Future<int> insertMovie(Movie movie) async {
    final db = await database;
    return await db.insert(
      Constants.tableMovies,
      movie.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ
  Future<List<Movie>> getAllMovies() async {
    final db = await database;
    final result = await db.query(
      Constants.tableMovies,
      orderBy: '${Constants.colId} DESC',
    );
    return result.map((row) => Movie.fromMap(row)).toList();
  }

  Future<Movie?> getMovieById(int id) async {
    final db = await database;
    final maps = await db.query(
      Constants.tableMovies,
      where: '${Constants.colId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Movie.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Movie>> getWatchlistMovies() async {
    final db = await database;
    final result = await db.query(
      Constants.tableMovies,
      where: '${Constants.colIsWatched} = ?',
      whereArgs: [0],
      orderBy: '${Constants.colId} DESC',
    );
    return result.map((row) => Movie.fromMap(row)).toList();
  }

  Future<List<Movie>> getWatchedMovies() async {
    final db = await database;
    final result = await db.query(
      Constants.tableMovies,
      where: '${Constants.colIsWatched} = ?',
      whereArgs: [1],
      orderBy: '${Constants.colId} DESC',
    );
    return result.map((row) => Movie.fromMap(row)).toList();
  }

  Future<List<Movie>> searchMovies(String query) async {
    final db = await database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return getAllMovies();
    }
    final result = await db.query(
      Constants.tableMovies,
      where: '${Constants.colTitle} LIKE ? OR ${Constants.colDirector} LIKE ?',
      whereArgs: ['%$trimmed%', '%$trimmed%'],
      orderBy: '${Constants.colId} DESC',
    );
    return result.map((row) => Movie.fromMap(row)).toList();
  }

  Future<List<Movie>> getMoviesByGenre(String genre) async {
    final db = await database;
    final result = await db.query(
      Constants.tableMovies,
      where: '${Constants.colGenre} = ?',
      whereArgs: [genre],
      orderBy: '${Constants.colId} DESC',
    );
    return result.map((row) => Movie.fromMap(row)).toList();
  }

  // UPDATE
  Future<int> updateMovie(Movie movie) async {
    final db = await database;
    return await db.update(
      Constants.tableMovies,
      movie.toMap(),
      where: '${Constants.colId} = ?',
      whereArgs: [movie.id],
    );
  }

  // DELETE
  Future<int> deleteMovie(int id) async {
    final db = await database;
    return await db.delete(
      Constants.tableMovies,
      where: '${Constants.colId} = ?',
      whereArgs: [id],
    );
  }

  // ================= SHARED MOVIES OPERATIONS =================

  Future<int> insertSharedMovie(SharedMovie item) async {
    final db = await database;
    return await db.insert(
      Constants.tableSharedMovies,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SharedMovie?> getSharedMovieByToken(String token) async {
    final db = await database;
    final results = await db.query(
      Constants.tableSharedMovies,
      where: '${Constants.colShareToken} = ?',
      whereArgs: [token.trim()],
    );
    if (results.isNotEmpty) {
      return SharedMovie.fromMap(results.first);
    }
    return null;
  }

  Future<List<SharedMovie>> getSharedMoviesByOwner(String ownerId) async {
    final db = await database;
    final results = await db.query(
      Constants.tableSharedMovies,
      where: '${Constants.colOwnerId} = ?',
      whereArgs: [ownerId],
      orderBy: '${Constants.colId} DESC',
    );
    return results.map((row) => SharedMovie.fromMap(row)).toList();
  }

  Future<List<SharedMovie>> getAllSharedMovies() async {
    final db = await database;
    final results = await db.query(
      Constants.tableSharedMovies,
      orderBy: '${Constants.colId} DESC',
    );
    return results.map((row) => SharedMovie.fromMap(row)).toList();
  }

  Future<int> revokeSharedMovie(String token, {required String ownerId}) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();
    return await db.update(
      Constants.tableSharedMovies,
      {
        Constants.colIsRevoked: 1,
        Constants.colRevokedAt: nowIso,
      },
      where: '${Constants.colShareToken} = ? AND ${Constants.colOwnerId} = ?',
      whereArgs: [token.trim(), ownerId],
    );
  }

  Future<int> deleteSharedMovie(int id) async {
    final db = await database;
    return await db.delete(
      Constants.tableSharedMovies,
      where: '${Constants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
