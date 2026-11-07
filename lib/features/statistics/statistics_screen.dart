import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/models/movie.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  String? _error;
  StatsSnapshot _stats = StatsSnapshot.empty();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movies = await DatabaseHelper.instance.getAllMovies();
      if (!mounted) return;
      setState(() {
        _stats = StatsSnapshot.fromMovies(movies);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load statistics: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR DIARY',
                        style: TextStyle(
                          color: Color(0xFFF7BA34),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF7BA34)),
      );
    }

    if (_error != null && _stats.total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadStats, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFF7BA34),
      onRefresh: _loadStats,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total logged',
                  value: '${_stats.total}',
                  icon: Icons.movie_filter_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Watched',
                  value: '${_stats.watched}',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Watchlist',
                  value: '${_stats.watchlist}',
                  icon: Icons.bookmark_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Avg rating',
                  value: _stats.averageRating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                  'Favorite genre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _stats.favoriteGenre ?? 'No genres yet',
                  style: const TextStyle(
                    color: Color(0xFFF7BA34),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Genre breakdown',
                  style: TextStyle(
                    color: Color(0xFF7E8B9C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (_stats.genreCounts.isEmpty)
                  const Text(
                    'Add movies to see which genres you log most.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  )
                else
                  ..._stats.genreCounts.map((entry) {
                    final ratio = _stats.total == 0
                        ? 0.0
                        : entry.count / _stats.total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GenreBar(
                        genre: entry.genre,
                        count: entry.count,
                        ratio: ratio,
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatsSnapshot {
  final int total;
  final int watched;
  final int watchlist;
  final double averageRating;
  final String? favoriteGenre;
  final List<GenreCount> genreCounts;

  const StatsSnapshot({
    required this.total,
    required this.watched,
    required this.watchlist,
    required this.averageRating,
    required this.favoriteGenre,
    required this.genreCounts,
  });

  factory StatsSnapshot.empty() {
    return const StatsSnapshot(
      total: 0,
      watched: 0,
      watchlist: 0,
      averageRating: 0,
      favoriteGenre: null,
      genreCounts: [],
    );
  }

  factory StatsSnapshot.fromMovies(List<Movie> movies) {
    final watched = movies.where((movie) => movie.isWatched).length;
    final rated = movies.where((movie) => movie.rating > 0).toList();
    final average = rated.isEmpty
        ? 0.0
        : rated.fold<double>(0, (sum, movie) => sum + movie.rating) /
              rated.length;

    final counts = <String, int>{};
    for (final movie in movies) {
      final genre = movie.genre.trim().isEmpty ? 'Unknown' : movie.genre.trim();
      counts[genre] = (counts[genre] ?? 0) + 1;
    }

    final sorted =
        counts.entries
            .map((entry) => GenreCount(genre: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            if (byCount != 0) return byCount;
            return a.genre.compareTo(b.genre);
          });

    return StatsSnapshot(
      total: movies.length,
      watched: watched,
      watchlist: movies.length - watched,
      averageRating: average,
      favoriteGenre: sorted.isEmpty ? null : sorted.first.genre,
      genreCounts: sorted,
    );
  }
}

class GenreCount {
  final String genre;
  final int count;

  const GenreCount({required this.genre, required this.count});
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242836)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF7BA34), size: 22),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7E8B9C),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreBar extends StatelessWidget {
  final String genre;
  final int count;
  final double ratio;

  const _GenreBar({
    required this.genre,
    required this.count,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                genre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF7E8B9C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFF202430),
            color: const Color(0xFFF7BA34),
          ),
        ),
      ],
    );
  }
}
