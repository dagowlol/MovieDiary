import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/features/library/library_screen.dart';
import 'package:movie/features/movie_detail/movie_detail_screen.dart';
import 'package:movie/features/movie_form/movie_form_screen.dart';
import 'package:movie/features/statistics/statistics_screen.dart';
import 'package:movie/features/watchlist/watchlist_screen.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/widgets/movie_card.dart';

class MovieDiaryApp extends StatelessWidget {
  const MovieDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Diary',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7BA34),
          surface: Color(0xFF161922),
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const LibraryScreen(),
      const WatchlistScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: const Color(0xFF161922),
        indicatorColor: const Color(0xFFF7BA34).withValues(alpha: 0.18),
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

/// Temporary browse hub so Detail can open for every movie until
/// `LibraryScreen` (Long) is wired in.
class _LibraryHub extends StatefulWidget {
  const _LibraryHub();

  @override
  State<_LibraryHub> createState() => _LibraryHubState();
}

class _LibraryHubState extends State<_LibraryHub> {
  List<Movie> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final movies = await DatabaseHelper.instance.getAllMovies();
      if (!mounted) return;
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load movies: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openForm({Movie? movie}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MovieFormScreen(movie: movie),
      ),
    );
    if (changed == true && mounted) {
      await _loadMovies();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      floatingActionButton: FloatingActionButton(
        heroTag: 'library-add',
        tooltip: 'Add movie',
        onPressed: () => _openForm(),
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
                        'YOUR COLLECTION',
                        style: TextStyle(
                          color: Color(0xFFF7BA34),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Library',
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

    if (_movies.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFF7BA34),
        onRefresh: _loadMovies,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.movie_filter_outlined, color: Color(0xFF6B7688), size: 48),
            SizedBox(height: 12),
            Text(
              'No movies logged yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to add your first diary entry.',
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
          );
        },
      ),
    );
  }
}
