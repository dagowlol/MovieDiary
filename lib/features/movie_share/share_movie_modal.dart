import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/models/shared_movie.dart';
import 'package:movie/services/movie_share_service.dart';

class ShareMovieModal extends StatefulWidget {
  final Movie movie;

  const ShareMovieModal({super.key, required this.movie});

  static Future<void> show(BuildContext context, Movie movie) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ShareMovieModal(movie: movie),
    );
  }

  @override
  State<ShareMovieModal> createState() => _ShareMovieModalState();
}

class _ShareMovieModalState extends State<ShareMovieModal> {
  SharedMovie? _sharedMovie;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateLink();
  }

  Future<void> _generateLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shared = await MovieShareService.instance.createShareLink(
        widget.movie,
      );
      if (!mounted) return;
      setState(() {
        _sharedMovie = shared;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF14161B), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã sao chép link chia sẻ vào clipboard!',
                style: TextStyle(
                  color: Color(0xFF14161B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF7BA34),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF333B4D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Modal Header
            Row(
              children: [
                const Icon(Icons.share_outlined, color: Color(0xFFF7BA34), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chia sẻ phim cho bạn bè',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Content body
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF7BA34)),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _generateLink,
                      child: const Text('Thử lại', style: TextStyle(color: Color(0xFFF7BA34))),
                    ),
                  ],
                ),
              )
            else if (_sharedMovie != null) ...[
              // Preview card of what friend will see
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF242836)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThumb(_sharedMovie!.posterUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_sharedMovie!.movieTitle} (${_sharedMovie!.releaseYear})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sharedMovie!.genre,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (_sharedMovie!.rating > 0)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFF7BA34), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${_sharedMovie!.rating.toStringAsFixed(1)} / 5.0',
                                  style: const TextStyle(
                                    color: Color(0xFFF7BA34),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (_sharedMovie!.review != null &&
                              _sharedMovie!.review!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '"${_sharedMovie!.review}"',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sharing link box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF262B38)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Color(0xFFF7BA34), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        _sharedMovie!.shareUrl,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCBD5E1),
                        side: const BorderSide(color: Color(0xFF2E3547)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7BA34),
                        foregroundColor: const Color(0xFF14161B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _copyToClipboard(_sharedMovie!.shareUrl),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text(
                        'Sao chép link',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(String? url) {
    if (url != null &&
        url.trim().isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url.trim(),
          width: 50,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF202430),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2B3142)),
      ),
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Color(0xFF6B7688), size: 22),
      ),
    );
  }
}
