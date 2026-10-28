import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:movie/models/movie.dart';
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

    return await openDatabase(
      path,
      version: Constants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${Constants.tableMovies} ADD COLUMN ${Constants.colPosterUrl} TEXT',
      );
    }
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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
