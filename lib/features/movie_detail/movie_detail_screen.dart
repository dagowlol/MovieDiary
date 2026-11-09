import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/features/movie_form/movie_form_screen.dart';
import 'package:movie/features/movie_share/share_movie_modal.dart';
import 'package:movie/models/movie.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _movie;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatWatchedDate(String raw) {
    if (raw.trim().isEmpty) return 'Not set';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  Future<void> _reload() async {
    final id = _movie.id;
    if (id == null) return;
    try {
      final fresh = await DatabaseHelper.instance.getMovieById(id);
      if (!mounted) return;
      if (fresh == null) {
        Navigator.of(context).maybePop(true);
        return;
      }
      setState(() {
        _movie = fresh;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh movie: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleWatched() async {
    if (_isBusy) return;
    final id = _movie.id;
    if (id == null) return;

    setState(() {
      _isBusy = true;
    });

    final nextWatched = !_movie.isWatched;
    final updated = _movie.copyWith(
      isWatched: nextWatched,
      watchedDate: nextWatched ? _todayIso() : '',
    );

    try {
      await DatabaseHelper.instance.updateMovie(updated);
      if (!mounted) return;
      setState(() {
        _movie = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextWatched ? 'Marked as watched' : 'Moved back to watchlist',
          ),
          backgroundColor: const Color(0xFFF7BA34),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update watch status: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _editMovie() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => MovieFormScreen(movie: _movie)),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _confirmDelete() async {
    if (_isBusy) return;
    final id = _movie.id;
    if (id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161922),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete this movie?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '"${_movie.title}" will be removed from your diary. This cannot be undone.',
            style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Confirm Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isBusy = true;
    });

    try {
      await DatabaseHelper.instance.deleteMovie(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${_movie.title}"'),
          backgroundColor: const Color(0xFFF7BA34),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).maybePop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete movie: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _movie.review?.trim() ?? '';
    final director = _movie.director.trim().isEmpty
        ? 'Unknown director'
        : _movie.director.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.of(context).maybePop(true),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MOVIE DETAILS',
                              style: TextStyle(
                                color: Color(0xFFF7BA34),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Diary entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('share-movie'),
                        tooltip: 'Share',
                        onPressed: _isBusy
                            ? null
                            : () => ShareMovieModal.show(context, _movie),
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Color(0xFFF7BA34),
                        ),
                      ),
                      IconButton(
                        key: const Key('edit-movie'),
                        tooltip: 'Edit',
                        onPressed: _isBusy ? null : _editMovie,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        key: const Key('delete-movie'),
                        tooltip: 'Delete',
                        onPressed: _isBusy ? null : _confirmDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailPoster(posterUrl: _movie.posterUrl),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _movie.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    director,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7E8B9C),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _InfoChip(
                                        icon: Icons.calendar_today_outlined,
                                        label: '${_movie.releaseYear}',
                                      ),
                                      _InfoChip(
                                        icon: Icons.category_outlined,
                                        label: _movie.genre.isEmpty
                                            ? 'Unknown'
                                            : _movie.genre,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _StarRow(rating: _movie.rating),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161922),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF242836)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Watch status',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _movie.isWatched
                                    ? 'Watched on ${_formatWatchedDate(_movie.watchedDate)}'
                                    : 'Saved to your watchlist',
                                style: const TextStyle(
                                  color: Color(0xFF7E8B9C),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _isBusy ? null : _toggleWatched,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF7BA34),
                                    foregroundColor: const Color(0xFF14161B),
                                    disabledBackgroundColor: const Color(
                                      0xFFF7BA34,
                                    ).withValues(alpha: 0.6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(
                                    _movie.isWatched
                                        ? Icons.bookmark_add_outlined
                                        : Icons.check_circle_outline,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _movie.isWatched
                                        ? 'Move to Watchlist'
                                        : 'Mark as Watched',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161922),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF242836)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal notes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                review.isEmpty
                                    ? 'No review yet. Tap Edit to add your thoughts.'
                                    : review,
                                style: TextStyle(
                                  color: review.isEmpty
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFCBD5E1),
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF161922),
          border: Border.all(color: const Color(0xFF262B38)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _DetailPoster extends StatelessWidget {
  final String? posterUrl;

  const _DetailPoster({this.posterUrl});

  @override
  Widget build(BuildContext context) {
    final url = posterUrl?.trim() ?? '';
    final hasUrl = url.startsWith('http://') || url.startsWith('https://');

    Widget child;
    if (hasUrl) {
      child = Image.network(
        url,
        width: 110,
        height: 154,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _PosterFallback(),
      );
    } else {
      child = const _PosterFallback();
    }

    return ClipRRect(borderRadius: BorderRadius.circular(14), child: child);
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 154,
      color: const Color(0xFF202430),
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Color(0xFF6B7688),
        size: 36,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF202430),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B3142)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFF7BA34)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;

  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          final filled = rating >= index + 1;
          final half = !filled && rating >= index + 0.5;
          return Icon(
            filled
                ? Icons.star_rounded
                : half
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            color: const Color(0xFFF7BA34),
            size: 22,
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
