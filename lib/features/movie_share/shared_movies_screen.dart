import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie/models/shared_movie.dart';
import 'package:movie/services/movie_share_service.dart';

class SharedMoviesScreen extends StatefulWidget {
  const SharedMoviesScreen({super.key});

  @override
  State<SharedMoviesScreen> createState() => _SharedMoviesScreenState();
}

class _SharedMoviesScreenState extends State<SharedMoviesScreen> {
  List<SharedMovie> _sharedList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSharedMovies();
  }

  Future<void> _loadSharedMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await MovieShareService.instance.getMySharedMovies();
      if (!mounted) return;
      setState(() {
        _sharedList = list;
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

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF14161B), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã sao chép link chia sẻ!',
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

  Future<void> _confirmRevoke(SharedMovie item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              'Thu hồi link chia sẻ?',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Khi thu hồi, bạn bè sẽ không thể sử dụng link này để import phim "${item.movieTitle}" vào Watchlist nữa.',
          style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await MovieShareService.instance.revokeShareLink(
        item.shareToken,
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thu hồi link chia sẻ "${item.movieTitle}"!'),
            backgroundColor: const Color(0xFFF7BA34),
          ),
        );
        _loadSharedMovies();
      }
    }
  }

  Future<void> _confirmDelete(SharedMovie item) async {
    if (item.id == null) return;
    final success = await MovieShareService.instance.deleteSharedMovie(item.id!);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa lịch sử chia sẻ "${item.movieTitle}"!'),
          backgroundColor: const Color(0xFFF7BA34),
        ),
      );
      _loadSharedMovies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161922),
        elevation: 0,
        title: const Text(
          'Quản lý phim đã chia sẻ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFF7BA34)),
            onPressed: _loadSharedMovies,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _buildBody(),
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

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSharedMovies,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sharedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.outbox_rounded, color: Color(0xFF6B7688), size: 48),
            const SizedBox(height: 14),
            const Text(
              'Chưa có phim nào được chia sẻ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy mở chi tiết một bộ phim và nhấn nút Chia sẻ.',
              style: TextStyle(color: Color(0xFF7E8B9C), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _sharedList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (ctx, index) {
        final item = _sharedList[index];
        final isRevoked = item.isRevoked || item.revokedAt != null;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161922),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRevoked
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : const Color(0xFF242836),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumb(item.posterUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.movieTitle} (${item.releaseYear})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.genre,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isRevoked
                                ? Colors.redAccent.withValues(alpha: 0.15)
                                : const Color(0xFFF7BA34).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRevoked ? '⛔ Đã thu hồi' : '🟢 Đang hoạt động',
                            style: TextStyle(
                              color: isRevoked
                                  ? Colors.redAccent
                                  : const Color(0xFFF7BA34),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Color(0xFF242836), height: 1),
              const SizedBox(height: 8),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isRevoked) ...[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF7BA34),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _copyLink(item.shareUrl),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Sao chép link', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _confirmRevoke(item),
                      icon: const Icon(Icons.block, size: 14),
                      label: const Text('Thu hồi link', style: TextStyle(fontSize: 12)),
                    ),
                  ] else ...[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _confirmDelete(item),
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Xóa lịch sử', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
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
