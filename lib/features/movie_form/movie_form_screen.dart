import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/utils/constants.dart';

class MovieFormScreen extends StatefulWidget {
  final Movie? movie;

  const MovieFormScreen({super.key, this.movie});

  @override
  State<MovieFormScreen> createState() => _MovieFormScreenState();
}

class _MovieFormScreenState extends State<MovieFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _directorController;
  late TextEditingController _yearController;
  late TextEditingController _posterUrlController;
  late TextEditingController _reviewController;

  late String _selectedGenre;
  late double _rating;
  late bool _isWatched;
  late String _watchedDate;

  bool _isSaving = false;

  bool get _isEditing => widget.movie != null;

  @override
  void initState() {
    super.initState();
    final movie = widget.movie;

    _titleController = TextEditingController(text: movie?.title ?? '');
    _directorController = TextEditingController(text: movie?.director ?? '');
    _yearController = TextEditingController(
      text: movie != null ? movie.releaseYear.toString() : '',
    );
    _posterUrlController = TextEditingController(text: movie?.posterUrl ?? '');
    _reviewController = TextEditingController(text: movie?.review ?? '');

    // Default genre: prioritize movie's existing genre or Constants list
    final initialGenre = movie?.genre;
    if (initialGenre != null && initialGenre.isNotEmpty) {
      _selectedGenre = initialGenre;
    } else {
      _selectedGenre = Constants.movieGenres.first;
    }

    _rating = movie?.rating ?? 0.0;
    _isWatched = movie?.isWatched ?? false;
    _watchedDate = movie?.watchedDate ?? '';

    // Listeners to live update the preview card
    _titleController.addListener(_onFieldChanged);
    _posterUrlController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _posterUrlController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _directorController.dispose();
    _yearController.dispose();
    _posterUrlController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _saveMovie() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final title = _titleController.text.trim();
      final director = _directorController.text.trim();
      final releaseYear = int.parse(_yearController.text.trim());
      final posterUrl = _posterUrlController.text.trim().isEmpty
          ? null
          : _posterUrlController.text.trim();
      final reviewText = _reviewController.text.trim();
      final review = reviewText.isEmpty ? null : reviewText;

      String finalWatchedDate = '';
      if (_isWatched) {
        if (_watchedDate.isNotEmpty) {
          finalWatchedDate = _watchedDate;
        } else {
          final now = DateTime.now();
          finalWatchedDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        }
      }

      final movieToSave = Movie(
        id: widget.movie?.id,
        title: title,
        director: director,
        releaseYear: releaseYear,
        genre: _selectedGenre,
        rating: _rating,
        isWatched: _isWatched,
        review: review,
        watchedDate: finalWatchedDate,
        posterUrl: posterUrl,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateMovie(movieToSave);
      } else {
        await DatabaseHelper.instance.insertMovie(movieToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Movie updated successfully!'
                  : 'Movie added successfully!',
            ),
            backgroundColor: const Color(0xFFF7BA34),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).maybePop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save movie: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false, String? optionalText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFF7BA34),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (optionalText != null)
            Text(
              optionalText,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? counter,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF161922),
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF4A5568),
        fontSize: 14,
      ),
      counter: counter,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF232835),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFF7BA34),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildPosterThumbnail() {
    final posterUrl = _posterUrlController.text.trim();
    final bool hasValidUrl =
        posterUrl.isNotEmpty && (posterUrl.startsWith('http://') || posterUrl.startsWith('https://'));

    if (hasValidUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          posterUrl,
          width: 68,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderPoster(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 68,
              height: 84,
              color: const Color(0xFF202430),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF7BA34),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildPlaceholderPoster();
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 68,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFF202430),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFF2B3142),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            color: const Color(0xFF6B7688).withValues(alpha: 0.8),
            size: 26,
          ),
          const SizedBox(height: 5),
          const Text(
            'Poster preview',
            style: TextStyle(
              color: Color(0xFF6B7688),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Collect all genre chips, placing selected genre safely
    final allGenres = List<String>.from(Constants.movieGenres);
    if (!allGenres.contains(_selectedGenre)) {
      allGenres.insert(0, _selectedGenre);
    }

    final enteredTitle = _titleController.text.trim();
    final displayTitle = enteredTitle.isEmpty ? 'New movie' : enteredTitle;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular back button
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF161922),
                              border: Border.all(
                                color: const Color(0xFF262B38),
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing ? 'EDIT COLLECTION' : 'ADD TO YOUR COLLECTION',
                                style: const TextStyle(
                                  color: Color(0xFFF7BA34),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isEditing ? 'Edit Movie' : 'Add Movie',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Movie Live Preview Card
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161922),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF242836),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildPosterThumbnail(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Add a poster URL to personalize your entry.',
                                  style: TextStyle(
                                    color: Color(0xFF7E8B9C),
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Movie Title Field
                    _buildFieldLabel('Movie title', isRequired: true),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: const Color(0xFFF7BA34),
                      decoration: _inputDecoration(
                        hintText: 'e.g. The Grand Budapest Hotel',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a movie title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Genre Field
                    _buildFieldLabel('Genre'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: allGenres.map((genre) {
                          final isSelected = genre == _selectedGenre;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedGenre = genre;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF7BA34)
                                      : const Color(0xFF161922),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFF7BA34)
                                        : const Color(0xFF262B38),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  genre,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF14161B)
                                        : const Color(0xFFCBD5E1),
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Release Year Field
                    _buildFieldLabel('Release year', isRequired: true),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: const Color(0xFFF7BA34),
                      decoration: _inputDecoration(
                        hintText: 'e.g. 2024',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter release year';
                        }
                        final year = int.tryParse(value.trim());
                        if (year == null ||
                            value.trim().length != 4 ||
                            year < 1888 ||
                            year > 2100) {
                          return 'Please enter a valid 4-digit year (e.g. 2024)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Poster URL Field
                    _buildFieldLabel('Poster URL', optionalText: 'Optional'),
                    TextFormField(
                      controller: _posterUrlController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: const Color(0xFFF7BA34),
                      decoration: _inputDecoration(
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Watch Status Toggle
                    _buildFieldLabel('Watch status'),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161922),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF232835),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          // Want to Watch
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isWatched = false;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isWatched
                                      ? const Color(0xFF262B37)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Want to Watch',
                                  style: TextStyle(
                                    color: !_isWatched
                                        ? const Color(0xFFF7BA34)
                                        : const Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: !_isWatched
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Watched
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isWatched = true;
                                  if (_watchedDate.isEmpty) {
                                    final now = DateTime.now();
                                    _watchedDate =
                                        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isWatched
                                      ? const Color(0xFF262B37)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Watched',
                                  style: TextStyle(
                                    color: _isWatched
                                        ? const Color(0xFFF7BA34)
                                        : const Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: _isWatched
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Personal Notes Field
                    _buildFieldLabel('Personal notes', optionalText: 'Optional'),
                    TextFormField(
                      controller: _reviewController,
                      maxLines: 4,
                      minLines: 4,
                      maxLength: 500,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      cursorColor: const Color(0xFFF7BA34),
                      decoration: _inputDecoration(
                        hintText: 'What did you think? Add a memorable moment...',
                      ).copyWith(
                        counter: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _reviewController,
                          builder: (context, value, child) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${value.text.length}/500',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CustomPaint(
                                    size: const Size(8, 8),
                                    painter: _CornerGripPainter(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF7BA34).withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveMovie,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7BA34),
                          foregroundColor: const Color(0xFF14161B),
                          disabledBackgroundColor:
                              const Color(0xFFF7BA34).withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF14161B),
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update Movie' : 'Save Movie',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel Button
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerGripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width, size.height - 5),
      Offset(size.width - 5, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - 2),
      Offset(size.width - 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
