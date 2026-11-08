import 'dart:convert';
import 'dart:math';
import 'package:movie/database/database_helper.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/models/shared_movie.dart';
import 'package:movie/services/auth_service.dart';

// Custom Exceptions
class ShareException implements Exception {
  final String message;
  const ShareException(this.message);

  @override
  String toString() => message;
}

class InvalidShareLinkException extends ShareException {
  const InvalidShareLinkException([super.message = 'Link chia sẻ không đúng định dạng của ứng dụng.']);
}

class ShareLinkNotFoundException extends ShareException {
  const ShareLinkNotFoundException([super.message = 'Link chia sẻ không tồn tại hoặc đã hết hạn.']);
}

class ShareLinkRevokedException extends ShareException {
  const ShareLinkRevokedException([super.message = 'Link chia sẻ này đã bị người gửi thu hồi.']);
}

class MovieAlreadyInWatchlistException extends ShareException {
  const MovieAlreadyInWatchlistException([super.message = 'Phim này đã có trong Watchlist của bạn.']);
}

class UserNotLoggedInException extends ShareException {
  const UserNotLoggedInException([super.message = 'Vui lòng đăng nhập trước khi thực hiện thao tác này.']);
}

class MovieShareService {
  static final MovieShareService instance = MovieShareService._init();
  MovieShareService._init();

  final Random _secureRandom = Random.secure();

  /// Generates a secure, unguessable, URL-safe random token
  String generateToken({int byteLength = 16}) {
    final bytes = List<int>.generate(
      byteLength,
      (_) => _secureRandom.nextInt(256),
    );
    final base64Token = base64UrlEncode(bytes).replaceAll('=', '');
    return 'mov_$base64Token';
  }

  /// Extracts the shareToken from an input string (either a full URL or raw token)
  String? parseShareToken(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Pattern 1: Full URL e.g. https://.../share/movie/{shareToken}
    final urlRegex = RegExp(
      r'^(?:https?:\/\/)?[^\/]+\/share\/movie\/([a-zA-Z0-9_\-]+)\/?$',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(trimmed);
    if (match != null) {
      return match.group(1);
    }

    // Pattern 2: Direct raw token e.g. mov_xxxxxxxx or token with at least 8 valid chars
    final tokenRegex = RegExp(r'^[a-zA-Z0-9_\-]{8,}$');
    if (tokenRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  /// Creates a new share link for a movie in user's diary
  Future<SharedMovie> createShareLink(
    Movie movie, {
    String? senderName,
    String? ownerId,
  }) async {
    final auth = AuthService.instance;
    if (!auth.isLoggedIn) {
      throw const UserNotLoggedInException(
        'Bạn cần đăng nhập để tạo link chia sẻ phim.',
      );
    }

    final effectiveOwnerId = ownerId ?? auth.currentUserId;
    final effectiveSenderName =
        (senderName != null && senderName.trim().isNotEmpty)
            ? senderName.trim()
            : auth.currentUserName;

    final token = generateToken();
    final sharedMovie = SharedMovie(
      shareToken: token,
      ownerId: effectiveOwnerId,
      senderName: effectiveSenderName,
      movieTitle: movie.title.trim(),
      director: movie.director.trim(),
      releaseYear: movie.releaseYear,
      genre: movie.genre.trim(),
      rating: movie.rating,
      review: movie.review?.trim(),
      posterUrl: movie.posterUrl?.trim(),
      createdAt: DateTime.now().toIso8601String(),
      isRevoked: false,
    );

    final id = await DatabaseHelper.instance.insertSharedMovie(sharedMovie);
    return sharedMovie.copyWith(id: id);
  }

  /// Validates an input link/token and returns preview data without altering recipient's data
  Future<SharedMovie> previewSharedMovie(String inputUrlOrToken) async {
    final token = parseShareToken(inputUrlOrToken);
    if (token == null) {
      throw const InvalidShareLinkException(
        'Link chia sẻ không hợp lệ. Vui lòng kiểm tra lại định dạng (ví dụ: http://localhost:5000/share/movie/{token}).',
      );
    }

    final shared = await DatabaseHelper.instance.getSharedMovieByToken(token);
    if (shared == null) {
      throw const ShareLinkNotFoundException(
        'Không tìm thấy phim được chia sẻ. Link có thể không tồn tại hoặc đã bị gỡ bỏ.',
      );
    }

    if (shared.isRevoked || shared.revokedAt != null) {
      throw const ShareLinkRevokedException(
        'Link chia sẻ này đã bị người gửi thu hồi.',
      );
    }

    return shared;
  }

  /// Checks if a movie title already exists in recipient's Watchlist
  Future<bool> isAlreadyInWatchlist(String movieTitle) async {
    final watchlist = await DatabaseHelper.instance.getWatchlistMovies();
    final normTitle = _normalizeTitle(movieTitle);
    return watchlist.any((m) => _normalizeTitle(m.title) == normTitle);
  }

  /// Adds a shared movie into recipient's Watchlist:
  /// - Status: Want to Watch (isWatched: false)
  /// - Recipient's personal rating: 0.0 (NOT sender's rating)
  /// - Recipient's personal review: null (NOT sender's review)
  /// - Does NOT create Watch Diary record
  /// - Does NOT alter sender's data
  Future<Movie> addToWatchlist(SharedMovie shared) async {
    final auth = AuthService.instance;
    if (!auth.isLoggedIn) {
      throw const UserNotLoggedInException(
        'Bạn cần đăng nhập để thêm phim này vào Watchlist cá nhân.',
      );
    }

    // Re-verify the link is not revoked
    final current = await DatabaseHelper.instance.getSharedMovieByToken(
      shared.shareToken,
    );
    if (current == null || current.isRevoked || current.revokedAt != null) {
      throw const ShareLinkRevokedException(
        'Link chia sẻ này đã bị người gửi thu hồi.',
      );
    }

    // Check duplicate in Watchlist
    final alreadyIn = await isAlreadyInWatchlist(shared.movieTitle);
    if (alreadyIn) {
      throw MovieAlreadyInWatchlistException(
        'Phim "${shared.movieTitle}" đã có trong Watchlist của bạn.',
      );
    }

    // Create fresh Watchlist record strictly isolated from sender's private notes
    final movie = Movie(
      title: shared.movieTitle,
      director: shared.director,
      releaseYear: shared.releaseYear,
      genre: shared.genre.isNotEmpty ? shared.genre : 'Movie',
      rating: 0.0, // Never copy sender's rating as personal rating
      isWatched: false, // Default: Want to watch
      review: null, // Never copy sender's review as personal review
      watchedDate: '',
      posterUrl: shared.posterUrl,
    );

    final id = await DatabaseHelper.instance.insertMovie(movie);
    return movie.copyWith(id: id);
  }

  /// Revokes a shared link so that future recipients can no longer import it
  Future<bool> revokeShareLink(String token, {String? ownerId}) async {
    final auth = AuthService.instance;
    final effectiveOwnerId = ownerId ?? auth.currentUserId;

    final rows = await DatabaseHelper.instance.revokeSharedMovie(
      token,
      ownerId: effectiveOwnerId,
    );
    return rows > 0;
  }

  /// Gets all shared links created by the current user
  Future<List<SharedMovie>> getMySharedMovies({String? ownerId}) async {
    final effectiveOwnerId = ownerId ?? AuthService.instance.currentUserId;
    return await DatabaseHelper.instance.getSharedMoviesByOwner(
      effectiveOwnerId,
    );
  }

  /// Deletes a shared movie entry
  Future<bool> deleteSharedMovie(int id) async {
    final rows = await DatabaseHelper.instance.deleteSharedMovie(id);
    return rows > 0;
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
