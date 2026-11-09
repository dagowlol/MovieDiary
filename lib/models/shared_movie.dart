import 'package:flutter/foundation.dart';
import 'package:movie/utils/constants.dart';

class SharedMovie {
  final int? id;
  final String shareToken;
  final String ownerId;
  final String senderName;
  final String movieTitle;
  final String director;
  final int releaseYear;
  final String genre;
  final double rating;
  final String? review;
  final String? posterUrl;
  final String createdAt;
  final String? revokedAt;
  final bool isRevoked;

  const SharedMovie({
    this.id,
    required this.shareToken,
    required this.ownerId,
    required this.senderName,
    required this.movieTitle,
    this.director = '',
    required this.releaseYear,
    required this.genre,
    this.rating = 0.0,
    this.review,
    this.posterUrl,
    required this.createdAt,
    this.revokedAt,
    this.isRevoked = false,
  });

  /// The public sharing URL for this movie
  String get shareUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin != 'null') {
          return '$origin/share/movie/$shareToken';
        }
      } catch (_) {}
    }
    return '${Constants.shareBaseUrl}/$shareToken';
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      Constants.colShareToken: shareToken,
      Constants.colOwnerId: ownerId,
      Constants.colSenderName: senderName,
      Constants.colMovieTitle: movieTitle,
      Constants.colDirector: director,
      Constants.colReleaseYear: releaseYear,
      Constants.colGenre: genre,
      Constants.colRating: rating,
      Constants.colReview: review,
      Constants.colPosterUrl: posterUrl,
      Constants.colCreatedAt: createdAt,
      Constants.colRevokedAt: revokedAt,
      Constants.colIsRevoked: isRevoked ? 1 : 0,
    };
    if (id != null) {
      map[Constants.colId] = id;
    }
    return map;
  }

  factory SharedMovie.fromMap(Map<String, dynamic> map) {
    return SharedMovie(
      id: map[Constants.colId] as int?,
      shareToken: map[Constants.colShareToken] as String? ?? '',
      ownerId: map[Constants.colOwnerId] as String? ?? '',
      senderName: map[Constants.colSenderName] as String? ?? 'Friend',
      movieTitle: map[Constants.colMovieTitle] as String? ?? '',
      director: map[Constants.colDirector] as String? ?? '',
      releaseYear: map[Constants.colReleaseYear] as int? ?? DateTime.now().year,
      genre: map[Constants.colGenre] as String? ?? 'Movie',
      rating: (map[Constants.colRating] as num?)?.toDouble() ?? 0.0,
      review: map[Constants.colReview] as String?,
      posterUrl: map[Constants.colPosterUrl] as String?,
      createdAt: map[Constants.colCreatedAt] as String? ?? '',
      revokedAt: map[Constants.colRevokedAt] as String?,
      isRevoked: (map[Constants.colIsRevoked] as int? ?? 0) == 1,
    );
  }

  SharedMovie copyWith({
    int? id,
    String? shareToken,
    String? ownerId,
    String? senderName,
    String? movieTitle,
    String? director,
    int? releaseYear,
    String? genre,
    double? rating,
    String? review,
    String? posterUrl,
    String? createdAt,
    String? revokedAt,
    bool? isRevoked,
  }) {
    return SharedMovie(
      id: id ?? this.id,
      shareToken: shareToken ?? this.shareToken,
      ownerId: ownerId ?? this.ownerId,
      senderName: senderName ?? this.senderName,
      movieTitle: movieTitle ?? this.movieTitle,
      director: director ?? this.director,
      releaseYear: releaseYear ?? this.releaseYear,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      posterUrl: posterUrl ?? this.posterUrl,
      createdAt: createdAt ?? this.createdAt,
      revokedAt: revokedAt ?? this.revokedAt,
      isRevoked: isRevoked ?? this.isRevoked,
    );
  }
}
