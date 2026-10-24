import 'package:movie/utils/constants.dart';

class Movie {
  final int? id; // Auto-increment primary key in SQLite (null before insertion)
  final String title; // Required, cannot be blank
  final String director; // Director name (default empty string if omitted)
  final int releaseYear; // e.g. 2024
  final String genre; // e.g. "Action", "Drama", "Sci-Fi"
  final double rating; // Rating from 0.0 to 5.0 stars
  final bool isWatched; // true: watched; false: in watchlist / plan-to-watch
  final String? review; // Optional personal review / thoughts
  final String watchedDate; // ISO date string 'YYYY-MM-DD' or timestamp

  Movie({
    this.id,
    required this.title,
    this.director = '',
    required this.releaseYear,
    required this.genre,
    this.rating = 0.0,
    this.isWatched = false,
    this.review,
    this.watchedDate = '',
  });

  // Convert Movie object to Map for SQLite insert/update
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      Constants.colTitle: title,
      Constants.colDirector: director,
      Constants.colReleaseYear: releaseYear,
      Constants.colGenre: genre,
      Constants.colRating: rating,
      Constants.colIsWatched: isWatched ? 1 : 0,
      Constants.colReview: review,
      Constants.colWatchedDate: watchedDate,
    };
    if (id != null) {
      map[Constants.colId] = id;
    }
    return map;
  }

  // Construct Movie object from SQLite row Map
  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map[Constants.colId] as int?,
      title: map[Constants.colTitle] as String? ?? '',
      director: map[Constants.colDirector] as String? ?? '',
      releaseYear: map[Constants.colReleaseYear] as int? ?? DateTime.now().year,
      genre: map[Constants.colGenre] as String? ?? '',
      rating: (map[Constants.colRating] as num?)?.toDouble() ?? 0.0,
      isWatched: (map[Constants.colIsWatched] as int? ?? 0) == 1,
      review: map[Constants.colReview] as String?,
      watchedDate: map[Constants.colWatchedDate] as String? ?? '',
    );
  }

  // Helper method for updating fields immutably
  Movie copyWith({
    int? id,
    String? title,
    String? director,
    int? releaseYear,
    String? genre,
    double? rating,
    bool? isWatched,
    String? review,
    String? watchedDate,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      director: director ?? this.director,
      releaseYear: releaseYear ?? this.releaseYear,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      isWatched: isWatched ?? this.isWatched,
      review: review ?? this.review,
      watchedDate: watchedDate ?? this.watchedDate,
    );
  }

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, director: $director, releaseYear: $releaseYear, '
        'genre: $genre, rating: $rating, isWatched: $isWatched, review: $review, watchedDate: $watchedDate)';
  }
}
