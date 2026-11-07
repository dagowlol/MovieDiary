import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/features/movie_detail/movie_detail_screen.dart';
import 'package:movie/features/movie_form/movie_form_screen.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/widgets/movie_card.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<Movie> _movies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movies = await DatabaseHelper.instance.getWatchlistMovies();
      if (!mounted) return;
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load watchlist: $e';
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

  Future<void> _openDetail(Movie movie) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movie: movie),
      ),
    );
    if (mounted) {
      await _loadMovies();
    }
  }

  Future<void> _addMovie() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const MovieFormScreen(),
      ),
    );
    if (added == true && mounted) {
      await _loadMovies();
    }
  }

  Future<void> _markWatched(Movie movie) async {
    final id = movie.id;
    if (id == null) return;

    final now = DateTime.now();
    final watchedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      await DatabaseHelper.instance.updateMovie(
        movie.copyWith(isWatched: true, watchedDate: watchedDate),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked "${movie.title}" as watched'),
          backgroundColor: const Color(0xFFF7BA34),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _loadMovies();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update movie: $e'),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'watchlist-add',
        tooltip: 'Add movie',
        onPressed: _addMovie,
        backgroundColor: const Color(0xFFF7BA34),
        foregroundColor: const Color(0xFF14161B),
        child: const Icon(Icons.add),
      ),
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
                        'PLAN TO WATCH',
                        style: TextStyle(
                          color: Color(0xFFF7BA34),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Watchlist',
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

    if (_error != null && _movies.isEmpty) {
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
              TextButton(
                onPressed: _loadMovies,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFF7BA34),
        onRefresh: _loadMovies,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.bookmark_outline, color: Color(0xFF6B7688), size: 48),
            SizedBox(height: 12),
            Text(
              'Your watchlist is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add a movie and keep it as Want to Watch.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7E8B9C)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFF7BA34),
      onRefresh: _loadMovies,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        itemCount: _movies.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final movie = _movies[index];
          return MovieCard(
            movie: movie,
            onTap: () => _openDetail(movie),
            onMarkWatched: () => _markWatched(movie),
          );
        },
      ),
    );
  }
}
