import 'package:flutter/material.dart';
import 'package:movie/database/database_helper.dart';
import 'package:movie/models/movie.dart';
import 'package:movie/models/movie_recommendation.dart';
import 'package:movie/services/recommendation_service.dart';

class AiRecommendationsSection extends StatefulWidget {
  final VoidCallback? onMovieAddedToWatchlist;

  const AiRecommendationsSection({
    super.key,
    this.onMovieAddedToWatchlist,
  });

  @override
  State<AiRecommendationsSection> createState() =>
      _AiRecommendationsSectionState();
}

class _AiRecommendationsSectionState extends State<AiRecommendationsSection> {
  RecommendationResult? _result;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await RecommendationService.instance.getRecommendations(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
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

  Future<void> _addToWatchlist(MovieRecommendation rec) async {
    try {
      final genreText = rec.genre.isNotEmpty ? rec.genre.first : 'Movie';
      final movie = Movie(
        title: rec.title,
        director: '',
        releaseYear: rec.year > 0 ? rec.year : DateTime.now().year,
        genre: genreText,
        rating: 0.0,
        isWatched: false,
        review: rec.reason,
        posterUrl: rec.posterUrl,
      );

      await DatabaseHelper.instance.insertMovie(movie);
      widget.onMovieAddedToWatchlist?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bookmark_added, color: Color(0xFF14161B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã thêm "${rec.title}" vào Watchlist!',
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm vào Watchlist: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAllRecommendationsSheet(List<MovieRecommendation> list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161922),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333B4D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🎬 Tất cả gợi ý phim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF242836), height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Container(
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
                                _buildPosterThumb(item.posterUrl, width: 60, height: 80),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.title} (${item.year})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.genre.join(' • '),
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
                                          color: const Color(0xFFF7BA34)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '⭐ AI Match: ${item.matchScore}%',
                                          style: const TextStyle(
                                            color: Color(0xFFF7BA34),
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
                            const SizedBox(height: 10),
                            Text(
                              '"${item.reason}"',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF7BA34),
                                  side: const BorderSide(
                                    color: Color(0xFFF7BA34),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  _addToWatchlist(item);
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.bookmark_add_outlined,
                                    size: 16),
                                label: const Text('Thêm vào Watchlist'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConfigDialog() {
    final service = RecommendationService.instance;
    final keyController = TextEditingController(text: service.apiKey);
    var selectedProvider = service.provider;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161922),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF242836)),
            ),
            title: const Row(
              children: [
                Icon(Icons.tune, color: Color(0xFFF7BA34)),
                SizedBox(width: 8),
                Text(
                  'Cấu hình AI API',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn AI Provider và nhập API Key của bạn:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedProvider,
                  dropdownColor: const Color(0xFF161922),
                  decoration: InputDecoration(
                    labelText: 'Provider',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0D0F14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'gemini',
                      child: Text('Google Gemini (Miễn phí)',
                          style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'openai',
                      child: Text('OpenAI / DeepSeek / Custom',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedProvider = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'Nhập API key...',
                    hintStyle: const TextStyle(color: Color(0xFF4A5568)),
                    filled: true,
                    fillColor: const Color(0xFF0D0F14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mẹo: Bạn cũng có thể truyền cờ --dart-define=AI_API_KEY=xxx khi build.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy',
                    style: TextStyle(color: Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7BA34),
                  foregroundColor: const Color(0xFF14161B),
                ),
                onPressed: () {
                  service.configure(
                    apiKey: keyController.text.trim(),
                    provider: selectedProvider,
                  );
                  Navigator.of(ctx).pop();
                  _fetchRecommendations(forceRefresh: true);
                },
                child: const Text('Lưu & Thử lại',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPosterThumb(String? url, {double width = 80, double height = 110}) {
    final bool hasValid = url != null &&
        url.trim().isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));

    if (hasValid) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url.trim(),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPosterPlaceholder(width: width, height: height),
        ),
      );
    }
    return _buildPosterPlaceholder(width: width, height: height);
  }

  Widget _buildPosterPlaceholder({double width = 80, double height = 110}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF202430),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2B3142)),
      ),
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: Color(0xFF6B7688),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎬 Gợi ý dành cho bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dựa trên lịch sử xem của bạn',
                      style: TextStyle(
                        color: Color(0xFF7E8B9C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: const Color(0xFF94A3B8),
                tooltip: 'Làm mới gợi ý',
                onPressed: _isLoading
                    ? null
                    : () => _fetchRecommendations(forceRefresh: true),
              ),
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                color: const Color(0xFF94A3B8),
                tooltip: 'Cấu hình AI',
                onPressed: _showConfigDialog,
              ),
            ],
          ),
        ),

        // Section Content
        if (_isLoading)
          _buildLoadingState()
        else if (_errorMessage != null)
          _buildErrorState(_errorMessage!)
        else if (_result != null)
          _buildResultContent(_result!)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242836)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFF7BA34),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'AI đang phân tích sở thích xem phim của bạn...',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.redAccent, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _fetchRecommendations(forceRefresh: true),
            child: const Text('Thử lại',
                style: TextStyle(color: Color(0xFFF7BA34))),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(RecommendationResult result) {
    if (result.status == RecommendationStatus.emptyHistory) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF242836)),
        ),
        child: const Column(
          children: [
            Icon(Icons.history_toggle_off, color: Color(0xFFF7BA34), size: 36),
            SizedBox(height: 10),
            Text(
              '🎬 Chưa đủ dữ liệu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Hãy thêm một vài bộ phim bạn đã xem để AI có thể hiểu sở thích của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7E8B9C),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    if (result.recommendations.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF242836)),
        ),
        child: Center(
          child: Text(
            result.message ??
                'Chưa thể tạo gợi ý phim mới. Vui lòng thử lại sau.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7E8B9C), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notice if in fallback mode
        if (result.isFallback)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7BA34).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF7BA34).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFF7BA34), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      result.message ??
                          'AI đang bận. Đang hiển thị gợi ý xem lại từ phim bạn chấm điểm cao!',
                      style: const TextStyle(
                        color: Color(0xFFF7BA34),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _fetchRecommendations(forceRefresh: true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Thử lại',
                        style: TextStyle(
                          color: Color(0xFFF7BA34),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Horizontal Recommendation Cards
        SizedBox(
          height: 270,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: result.recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = result.recommendations[index];
              return _buildRecommendationCard(item);
            },
          ),
        ),

        // "Xem thêm" Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  _showAllRecommendationsSheet(result.recommendations),
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text(
                'Xem thêm gợi ý',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF7BA34),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(MovieRecommendation item) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242836)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster with Match Score badge on top
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 115,
                  width: double.infinity,
                  color: const Color(0xFF202430),
                  child: item.posterUrl != null &&
                          item.posterUrl!.trim().isNotEmpty
                      ? Image.network(
                          item.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCardPosterPlaceholder(),
                        )
                      : _buildCardPosterPlaceholder(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F14).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF7BA34).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF7BA34), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${item.matchScore}%',
                        style: const TextStyle(
                          color: Color(0xFFF7BA34),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title & Year
          Text(
            '${item.title} ${item.year > 0 ? "(${item.year})" : ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),

          // Genre
          Text(
            item.genre.isNotEmpty ? item.genre.join(' • ') : 'Phim',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7E8B9C),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),

          // Reason quote
          Expanded(
            child: Text(
              '"${item.reason}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Add to Watchlist quick button
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF262B37),
                foregroundColor: const Color(0xFFF7BA34),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _addToWatchlist(item),
              icon: const Icon(Icons.bookmark_add_outlined, size: 14),
              label: const Text(
                '+ Watchlist',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPosterPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_filter_outlined, color: Color(0xFF6B7688), size: 30),
          SizedBox(height: 4),
          Text(
            'AI Pick',
            style: TextStyle(color: Color(0xFF6B7688), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
