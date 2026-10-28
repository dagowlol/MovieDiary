import 'package:flutter/material.dart';

class Constants {
  // Database Constants
  static const String dbName = 'movie_diary.db';
  static const int dbVersion = 2;
  static const String tableMovies = 'movies';

  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDirector = 'director';
  static const String colReleaseYear = 'release_year';
  static const String colGenre = 'genre';
  static const String colRating = 'rating';
  static const String colIsWatched = 'is_watched';
  static const String colReview = 'review';
  static const String colWatchedDate = 'watched_date';
  static const String colPosterUrl = 'poster_url';

  // Predefined Movie Genres
  static const List<String> movieGenres = [
    'Sci-Fi',
    'Action',
    'Drama',
    'Thriller',
    'Animation',
    'Comedy',
    'Adventure',
    'Crime',
    'Documentary',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
  ];

  // Colors & Styling
  static const Color primaryColor = Colors.indigo;
  static const Color accentColor = Colors.amber;
}
