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
    _reviewController = TextEditingController(text: movie?.review ?? '');

    // Genre selection: if movie has a genre not in the list, fallback or add it
    final initialGenre = movie?.genre;
    if (initialGenre != null && initialGenre.isNotEmpty) {
      _selectedGenre = initialGenre;
    } else {
      _selectedGenre = Constants.movieGenres.first;
    }

    _rating = movie?.rating ?? 0.0;
    _isWatched = movie?.isWatched ?? false;
    _watchedDate = movie?.watchedDate ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _directorController.dispose();
    _yearController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _selectWatchedDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_watchedDate.isNotEmpty) {
      final parsed = DateTime.tryParse(_watchedDate);
      if (parsed != null) {
        initial = parsed;
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _watchedDate =
            '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
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
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save movie: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    // Ensure selected genre is in the dropdown items list
    final genreItems = List<String>.from(Constants.movieGenres);
    if (!genreItems.contains(_selectedGenre)) {
      genreItems.insert(0, _selectedGenre);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Movie' : 'Add Movie'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Movie Title *',
                    hintText: 'e.g. Inception',
                    prefixIcon: Icon(Icons.movie_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a movie title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Director Field
                TextFormField(
                  controller: _directorController,
                  decoration: const InputDecoration(
                    labelText: 'Director',
                    hintText: 'e.g. Christopher Nolan',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Release Year Field
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Release Year *',
                    hintText: 'e.g. 2010',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),

                // Genre Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedGenre,
                  decoration: const InputDecoration(
                    labelText: 'Genre *',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: genreItems.map((genre) {
                    return DropdownMenuItem<String>(
                      value: genre,
                      child: Text(genre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGenre = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a genre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Rating Selector
                Card(
                  elevation: 0,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 22,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_rating.toStringAsFixed(1)} / 5.0',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: _rating,
                          min: 0.0,
                          max: 5.0,
                          divisions: 10,
                          label: _rating.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _rating = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Watched Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Watched',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _isWatched
                        ? 'Marked as watched'
                        : 'Plan to watch (Watchlist)',
                  ),
                  secondary: Icon(
                    _isWatched ? Icons.check_circle : Icons.watch_later_outlined,
                    color: _isWatched ? Colors.green : Colors.grey,
                  ),
                  value: _isWatched,
                  onChanged: (value) {
                    setState(() {
                      _isWatched = value;
                      if (_isWatched && _watchedDate.isEmpty) {
                        final now = DateTime.now();
                        _watchedDate =
                            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      }
                    });
                  },
                ),

                // Watched Date Picker (Visible only if watched is true)
                if (_isWatched) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectWatchedDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Watched',
                        prefixIcon: Icon(Icons.event_outlined),
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _watchedDate.isNotEmpty
                            ? _watchedDate
                            : 'Select watched date',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Review Field
                TextFormField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Personal Review',
                    hintText: 'Share your thoughts or notes on this movie...',
                    prefixIcon: Icon(Icons.rate_review_outlined),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMovie,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isEditing ? Icons.check : Icons.add),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : (_isEditing ? 'Update Movie' : 'Add Movie'),
                    style: const TextStyle(fontSize: 16),
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
