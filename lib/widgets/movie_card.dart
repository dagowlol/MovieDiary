import 'package:flutter/material.dart';
import 'package:movie/models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onMarkWatched;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.onMarkWatched,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: movie.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161922),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF242836)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PosterThumb(posterUrl: movie.posterUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.director.isEmpty
                            ? '${movie.releaseYear}'
                            : '${movie.director} · ${movie.releaseYear}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7E8B9C),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _GenreChip(label: movie.genre),
                          _RatingBadge(rating: movie.rating),
                        ],
                      ),
                      if (onMarkWatched != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onMarkWatched,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF7BA34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text(
                              'Mark as watched',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterThumb extends StatelessWidget {
  final String? posterUrl;

  const _PosterThumb({this.posterUrl});

  bool get _hasUrl {
    final url = posterUrl?.trim() ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          posterUrl!.trim(),
          width: 68,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _PosterPlaceholder(),
        ),
      );
    }
    return const _PosterPlaceholder();
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF202430),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF2B3142)),
      ),
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Color(0xFF6B7688),
        size: 26,
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;

  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF202430),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B3142)),
      ),
      child: Text(
        label.isEmpty ? 'Unknown' : label,
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF7BA34), size: 16),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
