import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/features/movie_detail/movie_detail_screen.dart';
import 'package:movie/features/movie_form/movie_form_screen.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/utils/constants.dart';
import 'package:movie/widgets/ai_recommendations_section.dart';
import 'package:movie/widgets/movie_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Movie> _allMovies = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedGenre = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
    _loadMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final movies = await DatabaseHelper.instance.getAllMovies();
      if (!mounted) return;
      setState(() {
        _allMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load movies: $e';
        _isLoading = false;
      });
    }
  }

  List<Movie> get _filteredMovies {
    final q = _query.trim().toLowerCase();
    return _allMovies.where((movie) {
      final matchesQuery = q.isEmpty ||
          movie.title.toLowerCase().contains(q) ||
          movie.director.toLowerCase().contains(q);
      final matchesGenre =
          _selectedGenre == 'All' || movie.genre == _selectedGenre;
      return matchesQuery && matchesGenre;
    }).toList();
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
    final filtered = _filteredMovies;

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: const Color(0xFFF7BA34),
                    decoration: InputDecoration(
                      hintText: 'Search by title or director',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF161922),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF242836)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF242836)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFF7BA34)),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildGenreChip('All'),
                      ...Constants.movieGenres.map(_buildGenreChip),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(filtered)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    final isSelected = _selectedGenre == genre;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(genre),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedGenre = genre;
          });
        },
        selectedColor: const Color(0xFFF7BA34),
        backgroundColor: const Color(0xFF161922),
        labelStyle: TextStyle(
          color: isSelected
              ? const Color(0xFF14161B)
              : const Color(0xFFCBD5E1),
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFFF7BA34)
              : const Color(0xFF262B38),
        ),
      ),
    );
  }

  Widget _buildBody(List<Movie> movies) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF7BA34)),
      );
    }

    if (_error != null && _allMovies.isEmpty) {
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
              TextButton(onPressed: _loadMovies, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (_allMovies.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFF7BA34),
        onRefresh: _loadMovies,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            AiRecommendationsSection(
              onMovieAddedToWatchlist: _loadMovies,
            ),
            const SizedBox(height: 40),
            const Icon(Icons.movie_filter_outlined,
                color: Color(0xFF6B7688), size: 48),
            const SizedBox(height: 12),
            const Text(
              'No movies logged yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add your first diary entry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7E8B9C)),
            ),
          ],
        ),
      );
    }

    if (movies.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFF7BA34),
        onRefresh: _loadMovies,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.search_off, color: Color(0xFF6B7688), size: 48),
            SizedBox(height: 12),
            Text(
              'No movies match your search',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final showAiSection = _query.isEmpty && _selectedGenre == 'All';

    return RefreshIndicator(
      color: const Color(0xFFF7BA34),
      onRefresh: _loadMovies,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        itemCount: movies.length + (showAiSection ? 1 : 0),
        itemBuilder: (context, index) {
          if (showAiSection && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AiRecommendationsSection(
                onMovieAddedToWatchlist: _loadMovies,
              ),
            );
          }
          final movieIndex = showAiSection ? index - 1 : index;
          final movie = movies[movieIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MovieCard(
              movie: movie,
              onTap: () => _openDetail(movie),
            ),
          );
        },
      ),
    );
  }
}
