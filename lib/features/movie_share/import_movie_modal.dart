import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie/models/shared_movie.dart';
import 'package:movie/services/auth_service.dart';
import 'package:movie/services/movie_share_service.dart';

class ImportMovieModal extends StatefulWidget {
  final VoidCallback? onMovieAddedToWatchlist;

  const ImportMovieModal({super.key, this.onMovieAddedToWatchlist});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onMovieAddedToWatchlist,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) =>
          ImportMovieModal(onMovieAddedToWatchlist: onMovieAddedToWatchlist),
    );
  }

  @override
  State<ImportMovieModal> createState() => _ImportMovieModalState();
}

class _ImportMovieModalState extends State<ImportMovieModal> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  SharedMovie? _previewMovie;
  bool _isAlreadyInWatchlist = false;
  bool _isAdding = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      _linkController.text = data.text!.trim();
      _fetchPreview();
    }
  }

  Future<void> _fetchPreview() async {
    final input = _linkController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập hoặc dán link chia sẻ phim.';
        _previewMovie = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previewMovie = null;
    });

    try {
      final shared = await MovieShareService.instance.previewSharedMovie(input);
      final alreadyIn = await MovieShareService.instance.isAlreadyInWatchlist(
        shared.movieTitle,
      );

      if (!mounted) return;
      setState(() {
        _previewMovie = shared;
        _isAlreadyInWatchlist = alreadyIn;
        _isLoading = false;
      });
    } on ShareException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi không xác định: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addToWatchlist() async {
    if (_previewMovie == null) return;

    final auth = AuthService.instance;
    if (!auth.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      await MovieShareService.instance.addToWatchlist(_previewMovie!);
      if (!mounted) return;

      widget.onMovieAddedToWatchlist?.call();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bookmark_added, color: Color(0xFF14161B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã thêm "${_previewMovie!.movieTitle}" vào Watchlist của bạn!',
                  style: const TextStyle(
                    color: Color(0xFF14161B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF7BA34),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on ShareException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
      setState(() {
        _isAdding = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
      setState(() {
        _isAdding = false;
      });
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFFF7BA34)),
            SizedBox(width: 8),
            Text(
              'Yêu cầu đăng nhập',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Bạn cần đăng nhập tài khoản để có thể lưu phim vào Watchlist cá nhân.',
          style: TextStyle(color: Color(0xFFCBD5E1), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7BA34),
              foregroundColor: const Color(0xFF14161B),
            ),
            onPressed: () {
              AuthService.instance.setLoggedIn(true);
              Navigator.of(ctx).pop();
              _addToWatchlist();
            },
            child: const Text('Đăng nhập ngay',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
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

              // Title
              Row(
                children: [
                  const Icon(Icons.link, color: Color(0xFFF7BA34), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Nhập link chia sẻ phim',
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
              const SizedBox(height: 12),

              // Input field
              TextField(
                controller: _linkController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Dán link chia sẻ hoặc token...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0D0F14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF242836)),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, color: Color(0xFFF7BA34)),
                    tooltip: 'Dán từ clipboard',
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                onSubmitted: (_) => _fetchPreview(),
              ),

              const SizedBox(height: 10),

              // Check button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF262B37),
                  foregroundColor: const Color(0xFFF7BA34),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _fetchPreview,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF7BA34),
                        ),
                      )
                    : const Icon(Icons.search, size: 18),
                label: Text(
                  _isLoading ? 'Đang kiểm tra link...' : 'Kiểm tra & Xem trước',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // Error display
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Preview card
              if (_previewMovie != null) ...[
                const SizedBox(height: 16),
                const Text(
                  '🎬 THÔNG TIN PHIM ĐƯỢC CHIA SẺ',
                  style: TextStyle(
                    color: Color(0xFFF7BA34),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF242836)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildThumb(_previewMovie!.posterUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_previewMovie!.movieTitle} (${_previewMovie!.releaseYear})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _previewMovie!.genre,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF202430),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF2B3142),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_outline,
                                          color: Color(0xFFF7BA34), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Từ: ${_previewMovie!.senderName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (_previewMovie!.rating > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFF7BA34), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Đánh giá của bạn bè: ${_previewMovie!.rating.toStringAsFixed(1)} / 5.0',
                              style: const TextStyle(
                                color: Color(0xFFF7BA34),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_previewMovie!.review != null &&
                          _previewMovie!.review!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${_previewMovie!.review}"',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      const Text(
                        'ℹ️ Đánh giá và nhận xét của bạn bè chỉ mang tính tham khảo. Khi thêm vào Watchlist, điểm rating và review cá nhân của bạn sẽ để trống.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                // Already in Watchlist notification
                if (_isAlreadyInWatchlist) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7BA34).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF7BA34).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFFF7BA34), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Phim này đã có trong Watchlist của bạn.',
                            style: TextStyle(
                              color: Color(0xFFF7BA34),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons: Add to Watchlist & Cancel
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFCBD5E1),
                          side: const BorderSide(color: Color(0xFF2E3547)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
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
                        onPressed: (_isAlreadyInWatchlist || _isAdding)
                            ? null
                            : _addToWatchlist,
                        icon: _isAdding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF14161B),
                                ),
                              )
                            : const Icon(Icons.bookmark_add, size: 18),
                        label: Text(
                          _isAlreadyInWatchlist
                              ? 'Đã có trong Watchlist'
                              : 'Thêm vào Watchlist',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
          width: 58,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 58,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFF202430),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2B3142)),
      ),
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Color(0xFF6B7688), size: 24),
      ),
    );
  }
}
