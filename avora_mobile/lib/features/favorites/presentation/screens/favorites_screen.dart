import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';
import 'package:avora_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:avora_mobile/features/home/presentation/widgets/home_helpers.dart';

/// Màn hình Danh sách Khách sạn Yêu thích (Wishlist).
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final favoriteIds = homeState.favorites;

    // Lọc danh sách khách sạn đã yêu thích từ danh sách khách sạn của hệ thống
    final favoriteHotels = homeState.hotels
        .where((h) => favoriteIds.contains(h.hotelId))
        .where((h) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final name = h.name.toLowerCase();
          final city = (h.cityName ?? '').toLowerCase();
          final addr = (h.address ?? '').toLowerCase();
          return name.contains(q) || city.contains(q) || addr.contains(q);
        })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          key: const Key('favorites_back_button'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách yêu thích',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${favoriteIds.length} chỗ nghỉ đã lưu',
              style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
            ),
          ],
        ),
        actions: [
          if (favoriteIds.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.white,
              ),
              tooltip: 'Xóa tất cả',
              onPressed: () => _confirmClearAll(context),
            ),
        ],
      ),
      body: favoriteIds.isEmpty
          ? _buildEmptyState(context)
          : CustomScrollView(
              slivers: [
                // Thanh tìm kiếm nhanh trong danh sách yêu thích
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm trong danh sách đã lưu...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF0284C7),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Kết quả tìm kiếm rỗng trong danh sách
                if (favoriteHotels.isEmpty && _searchQuery.isNotEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Không tìm thấy khách sạn phù hợp với từ khóa.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  // Danh sách thẻ khách sạn yêu thích
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final hotel = favoriteHotels[index];
                        return _buildFavoriteHotelCard(context, hotel);
                      }, childCount: favoriteHotels.length),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Trạng thái rỗng khi chưa có khách sạn nào được yêu thích
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 64,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có khách sạn nào được lưu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn vào biểu tượng trái tim ở bất kỳ khách sạn nào để lưu lại danh sách yêu thích cho chuyến đi sắp tới.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              icon: const Icon(Icons.travel_explore, size: 18),
              label: const Text(
                'Khám phá khách sạn ngay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ khách sạn yêu thích
  Widget _buildFavoriteHotelCard(BuildContext context, HotelModel hotel) {
    final imageSrc =
        hotel.thumbnail ??
        (hotel.images.isNotEmpty ? hotel.images.first : null) ??
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh và nút Favorite
          Stack(
            children: [
              Image.network(
                imageSrc,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: const Color(0xFFCBD5E1),
                  child: const Icon(Icons.image_not_supported, size: 36),
                ),
              ),
              // Nút xóa khỏi yêu thích
              Positioned(
                top: 10,
                right: 10,
                child: InkWell(
                  onTap: () {
                    ref
                        .read(homeProvider.notifier)
                        .toggleFavorite(hotel.hotelId);
                    showHomeSnackBar(
                      context,
                      'Đã xóa ${hotel.name} khỏi danh sách yêu thích',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Badge Sao
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${hotel.starQuality} sao',
                        style: const TextStyle(
                          color: Colors.white,
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

          // Thông tin khách sạn
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        hotel.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003580),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        hotel.starRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 13,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hotel.address ?? hotel.cityName ?? 'Việt Nam',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${homeCurrencyFormatter.format(hotel.price)} VND',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF003580),
                          ),
                        ),
                        const Text(
                          'đã bao gồm thuế & phí',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003580),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        showHomeSnackBar(
                          context,
                          'Đang mở trang chi tiết đặt phòng cho ${hotel.name}',
                        );
                      },
                      child: const Text(
                        'Đặt phòng ngay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại xác nhận xóa tất cả mục yêu thích
  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa danh sách yêu thích'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ khách sạn khỏi danh sách yêu thích?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final ids = List<String>.from(ref.read(homeProvider).favorites);
              for (final id in ids) {
                ref.read(homeProvider.notifier).toggleFavorite(id);
              }
              showHomeSnackBar(context, 'Đã xóa toàn bộ danh sách yêu thích.');
            },
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
