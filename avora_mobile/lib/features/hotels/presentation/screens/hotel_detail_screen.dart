import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/providers/home_provider.dart';
import '../../home/presentation/widgets/home_helpers.dart';
import '../../data/models/hotel_detail_model.dart';
import '../../data/models/room_capacity_helper.dart';
import '../providers/hotel_detail_provider.dart';
import '../widgets/hotel_detail_booking_modal.dart';
import '../widgets/hotel_detail_lightbox.dart';
import '../widgets/hotel_detail_map_modal.dart';

/// Màn hình Chi tiết Khách sạn (Hotel Detail Screen)
/// Thiết kế chuẩn mực, chuyển thể 1:1 từ HotelDetailPage của bản Web.
class HotelDetailScreen extends ConsumerStatefulWidget {
  final String hotelId;

  const HotelDetailScreen({
    super.key,
    required this.hotelId,
  });

  @override
  ConsumerState<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends ConsumerState<HotelDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _roomsSectionKey = GlobalKey();
  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  late PageController _galleryPageController;
  int _currentGalleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _galleryPageController = PageController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _galleryPageController.dispose();
    super.dispose();
  }

  void _scrollToRooms() {
    final context = _roomsSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _shareHotel(String hotelName) {
    Clipboard.setData(ClipboardData(text: 'https://avora.vn/hotels/${widget.hotelId}'));
    showHomeSnackBar(context, 'Đã sao chép liên kết khách sạn $hotelName vào bộ nhớ tạm!');
  }

  IconData _getAmenityIcon(String? type, String name) {
    final t = (type ?? '').toUpperCase();
    final n = name.toLowerCase();

    if (t.contains('POOL') || n.contains('bể bơi') || n.contains('hồ bơi')) {
      return Icons.pool;
    }
    if (t.contains('INTERNET') || t.contains('WIFI') || n.contains('wifi') || n.contains('mạng')) {
      return Icons.wifi;
    }
    if (n.contains('biển') || n.contains('beach')) {
      return Icons.beach_access;
    }
    if (n.contains('ăn sáng') || n.contains('nhà hàng') || n.contains('ẩm thực')) {
      return Icons.restaurant;
    }
    if (n.contains('xe') || n.contains('đưa đón') || n.contains('shuttle')) {
      return Icons.airport_shuttle;
    }
    if (n.contains('spa') || n.contains('massage')) {
      return Icons.spa;
    }
    if (n.contains('gym') || n.contains('thể hình') || n.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (n.contains('bar') || n.contains('cocktail')) {
      return Icons.local_bar;
    }
    return Icons.auto_awesome;
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(hotelDetailProvider(widget.hotelId));
    final detailNotifier = ref.read(hotelDetailProvider(widget.hotelId).notifier);

    final homeState = ref.watch(homeProvider);
    final isFavorite = homeState.favorites.contains(widget.hotelId);

    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final guestName = currentUser?.fullName ?? currentUser?.email ?? 'Quý khách Avora';

    if (detailState.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003580),
          foregroundColor: Colors.white,
          title: const Text('Chi tiết khách sạn', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF003580)),
              SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu từ cơ sở dữ liệu...',
                style: TextStyle(
                  color: Color(0xFF003580),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (detailState.errorMessage != null && detailState.hotel == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003580),
          foregroundColor: Colors.white,
          title: const Text('Chi tiết khách sạn'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Không thể tải thông tin khách sạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detailState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => detailNotifier.loadHotelDetail(),
                  child: const Text('Thử tải lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hotel = detailState.hotel!;
    final images = hotel.images.isNotEmpty
        ? hotel.images
        : [
            hotel.thumbnail ??
                'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80'
          ];

    // Tính giá thấp nhất để hiển thị ở bottom bar
    num lowestPrice = 0;
    if (hotel.rooms.isNotEmpty) {
      lowestPrice = hotel.rooms.map((r) => r.price).reduce((a, b) => a < b ? a : b);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      // App Bar với đầy đủ hành động như Web
      appBar: AppBar(
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          hotel.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          // Nút Yêu thích
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
            ),
            tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
            onPressed: () {
              detailNotifier.toggleFavorite();
              showHomeSnackBar(
                context,
                isFavorite
                    ? 'Đã xóa ${hotel.name} khỏi danh sách yêu thích'
                    : 'Đã lưu ${hotel.name} vào danh sách yêu thích',
              );
            },
          ),
          // Nút Chia sẻ
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Chia sẻ',
            onPressed: () => _shareHotel(hotel.name),
          ),
          // Nút Mở bộ sưu tập ảnh
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            tooltip: 'Xem ảnh',
            onPressed: () => detailNotifier.setLightboxOpen(true, 0),
          ),
        ],
      ),

      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => detailNotifier.loadHotelDetail(),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 1. BREADCRUMBS & PREFERRED BADGE ─────────────────────
                  _buildBreadcrumbsAndPreferred(hotel),

                  // ─── 2. PHOTO GALLERY (CAROUSEL + LIGHTBOX TRIGGER) ───────
                  _buildGallerySection(hotel, images, detailNotifier),

                  // ─── 3. HOTEL HEADER CARD (TITLE, STARS, RATING, ACTIONS) ──
                  _buildHeaderCard(hotel, isFavorite, detailNotifier),

                  // ─── 4. AMENITIES SECTION ─────────────────────────────────
                  _buildAmenitiesSection(hotel),

                  // ─── 5. LOCATION & LANDMARKS CARD ─────────────────────────
                  _buildLocationCard(hotel, detailNotifier),

                  // ─── 6. AVAILABLE ROOMS & PRICING TABLE ───────────────────
                  _buildRoomsSection(hotel, detailState, guestName),

                  // ─── 7. CUSTOMER REVIEWS SECTION ──────────────────────────
                  _buildReviewsSection(hotel),
                ],
              ),
            ),
          ),

          // ─── 8. STICKY BOTTOM BOOKING BAR ─────────────────────────────────
          _buildStickyBottomBar(hotel, lowestPrice),

          // ─── 9. LIGHTBOX MODAL OVERLAY ────────────────────────────────────
          if (detailState.isLightboxOpen)
            Positioned.fill(
              child: HotelDetailLightbox(
                images: images,
                initialIndex: detailState.activePhotoIndex,
                hotelName: hotel.name,
                onClose: () => detailNotifier.setLightboxOpen(false),
              ),
            ),

          // ─── 10. MAP MODAL OVERLAY ────────────────────────────────────────
          if (detailState.isMapModalOpen)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: HotelDetailMapModal(
                  hotel: hotel,
                  onClose: () => detailNotifier.setMapModalOpen(false),
                ),
              ),
            ),

          // ─── 11. BOOKING CONFIRMATION MODAL OVERLAY ───────────────────────
          if (detailState.selectedRoomForBooking != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: HotelDetailBookingModal(
                  hotel: hotel,
                  room: detailState.selectedRoomForBooking!,
                  guestName: guestName,
                  formattedStayDates: detailState.formattedStayDates,
                  nights: detailState.nights,
                  adults: detailState.adults,
                  children: detailState.children,
                  rooms: detailState.rooms,
                  onComplete: () {
                    detailNotifier.selectRoomForBooking(null);
                    showHomeSnackBar(
                      context,
                      'Đặt phòng thành công! Đơn đặt chỗ đã được ghi nhận trong cơ sở dữ liệu.',
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildBreadcrumbsAndPreferred(HotelDetailModel hotel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go(AppRoutes.home),
                        child: const Text(
                          'Trang chủ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF006CE4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(' / ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const Text(
                        'Khách sạn VN',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF006CE4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hotel.cityName != null) ...[
                        const Text(' / ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        Text(
                          hotel.cityName!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF006CE4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Text(' / ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      Text(
                        hotel.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Preferred+ Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Color(0xFF006CE4)),
                SizedBox(width: 5),
                Text(
                  'Chỗ nghỉ đạt chuẩn Avora Preferred+',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006CE4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(
    HotelDetailModel hotel,
    List<String> images,
    HotelDetailNotifier notifier,
  ) {
    return Container(
      height: 240,
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _galleryPageController,
            itemCount: images.length,
            onPageChanged: (idx) {
              setState(() => _currentGalleryIndex = idx);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => notifier.setLightboxOpen(true, index),
                child: Image.network(
                  images[index],
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFCBD5E1),
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              );
            },
          ),

          // Nút xem tất cả ảnh (Floating camera badge)
          Positioned(
            bottom: 12,
            right: 12,
            child: InkWell(
              onTap: () => notifier.setLightboxOpen(true, _currentGalleryIndex),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentGalleryIndex + 1}/${images.length} hình ảnh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dots indicator
          if (images.length > 1)
            Positioned(
              bottom: 14,
              left: 14,
              child: Row(
                children: List.generate(
                  images.length > 8 ? 8 : images.length,
                  (index) => Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentGalleryIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    HotelDetailModel hotel,
    bool isFavorite,
    HotelDetailNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars & Badges
          Row(
            children: [
              Row(
                children: List.generate(
                  hotel.starQuality,
                  (i) => const Icon(Icons.star, size: 15, color: Color(0xFFF59E0B)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'Khách sạn ${hotel.starQuality} sao',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hotel.cityName != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    hotel.cityName!,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Hotel Title
          Text(
            hotel.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF003580),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Location Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF006CE4)),
              const SizedBox(width: 4),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    children: [
                      TextSpan(text: '${hotel.fullAddress.isNotEmpty ? hotel.fullAddress : hotel.address} '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: InkWell(
                          onTap: () => notifier.setMapModalOpen(true),
                          child: const Text(
                            '— Hiển thị trên bản đồ',
                            style: TextStyle(
                              color: Color(0xFF006CE4),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Score Box & Action Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Score Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003580),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hotel.starRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.scoreLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${hotel.reviewsCount} đánh giá từ cơ sở dữ liệu',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFF334155),
                    size: 17,
                  ),
                  label: Text(
                    isFavorite ? 'Đã yêu thích' : 'Yêu thích',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFF334155),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isFavorite ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
                    ),
                    backgroundColor: isFavorite ? const Color(0xFFFEF2F2) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    notifier.toggleFavorite();
                    showHomeSnackBar(
                      context,
                      isFavorite
                          ? 'Đã xóa ${hotel.name} khỏi yêu thích'
                          : 'Đã lưu ${hotel.name} vào yêu thích',
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bolt, color: Colors.white, size: 17),
                  label: const Text(
                    'Đặt phòng ngay',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006CE4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _scrollToRooms,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(HotelDetailModel hotel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF006CE4), size: 18),
              const SizedBox(width: 8),
              Text(
                'Tiện nghi trong cơ sở dữ liệu (${hotel.facilities.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF003580),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amenities Grid
          if (hotel.facilities.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.2,
              ),
              itemCount: hotel.facilities.length,
              itemBuilder: (context, index) {
                final item = hotel.facilities[index];
                final icon = _getAmenityIcon(item.type, item.name);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFF006CE4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
          ],

          // Hotel Description Text
          Text(
            hotel.description.isNotEmpty
                ? hotel.description
                : 'Chưa có mô tả chi tiết trong cơ sở dữ liệu.',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(HotelDetailModel hotel, HotelDetailNotifier notifier) {
    final locationLabel = hotel.districtName ?? hotel.cityName ?? 'khu vực';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF006CE4), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Vị trí tại $locationLabel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF003580),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Điểm ${hotel.starRating.toStringAsFixed(1)} / 10',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006CE4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Map Preview Thumbnail
          InkWell(
            onTap: () => notifier.setMapModalOpen(true),
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=600&q=80',
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.25),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_outlined, color: Color(0xFF006CE4), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Xem trên bản đồ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFF003580),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Landmarks List
          _buildLandmarkItem('📍', 'Địa chỉ', hotel.address),
          if (hotel.wardName != null) ...[
            const Divider(height: 12),
            _buildLandmarkItem('🏘️', 'Phường/Xã', hotel.wardName!),
          ],
          if (hotel.districtName != null) ...[
            const Divider(height: 12),
            _buildLandmarkItem('🏛️', 'Quận/Huyện', hotel.districtName!),
          ],
          if (hotel.cityName != null) ...[
            const Divider(height: 12),
            _buildLandmarkItem('🏙️', 'Thành phố', hotel.cityName!),
          ],

          // Cancellation Policy Banner
          if (hotel.cancellationPolicy != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hotel.cancellationPolicy!.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLandmarkItem(String emoji, String title, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            title,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsSection(
    HotelDetailModel hotel,
    HotelDetailState detailState,
    String guestName,
  ) {
    return Container(
      key: _roomsSectionKey,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phòng còn trống & Bảng giá chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF003580),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Dữ liệu bảng giá và phòng trống được tải trực tiếp từ cơ sở dữ liệu',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Stay Date Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF003580)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${detailState.formattedStayDates} (${detailState.adults} người lớn${detailState.children > 0 ? ', ${detailState.children} trẻ em' : ''} · ${detailState.rooms} phòng)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List of Room Cards
          if (hotel.rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có thông tin phòng trống trong cơ sở dữ liệu.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hotel.rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final room = hotel.rooms[index];
                return _buildRoomCard(room, detailState, hotel, guestName);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(
    RoomTypeDetailModel room,
    HotelDetailState detailState,
    HotelDetailModel hotel,
    String guestName,
  ) {
    final capDetails = RoomCapacityHelper.getRoomCapacityDetails(
      bedType: room.bedType,
      maxAdults: room.maxAdults,
      maxChildren: room.maxChildren,
    );

    final guestsPerRoom = detailState.guestsPerRoom;
    final isCapacityExceeded = guestsPerRoom > capDetails.maxCapacity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCapacityExceeded ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isCapacityExceeded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Header / Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: room.isVip ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.isVip ? '⭐ Hạng phòng VIP' : 'Hạng phòng tiêu chuẩn',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: room.isVip ? const Color(0xFFB45309) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  room.availableRooms > 0 ? '${room.availableRooms} phòng trống' : 'Hết phòng',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: room.availableRooms > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Name
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF003580),
                  ),
                ),
                const SizedBox(height: 10),

                // Room Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    room.image ??
                        (hotel.images.length > 1 ? hotel.images[1] : hotel.thumbnail) ??
                        'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=600&q=80',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.bed, size: 40, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Room Specs
                if (room.roomSize != null)
                  _buildSpecRow('📐', 'Diện tích: ${room.roomSize}'),
                _buildSpecRow(
                  '👥',
                  'Sức chứa: ${capDetails.standardBeds} giường tiêu chuẩn (${capDetails.standardCapacity} người)${capDetails.hasExtraBed ? ' + 1 giường phụ' : ''} = Tối đa ${capDetails.maxCapacity} người',
                ),
                if (room.bedType != null)
                  _buildSpecRow('🛏️', room.bedType!),
                const SizedBox(height: 10),

                // Benefits
                _buildBenefitItem(room.policyDescription),
                _buildBenefitItem('Xác nhận đặt phòng tức thì'),
                _buildBenefitItem('Thanh toán tại quầy lễ tân khi nhận phòng'),
                const SizedBox(height: 10),

                // Capacity Alert
                if (isCapacityExceeded)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⛔ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                              children: [
                                TextSpan(
                                  text:
                                      'Không được cho phép booking $guestsPerRoom người vào phòng này!\n',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text:
                                      'Phòng chỉ gồm ${capDetails.standardBeds} giường tiêu chuẩn (${capDetails.standardCapacity} người) + 1 giường phụ = tối đa ${capDetails.maxCapacity} người.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (guestsPerRoom == 5 && capDetails.maxCapacity == 5)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🛏️ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            'Đã kích hoạt 01 giường phụ: 4 người ở 2 giường tiêu chuẩn + 1 người ở giường phụ (tổng 5 người).',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Urgency flame tag
                if (room.availableRooms > 0 && room.availableRooms <= 5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          'Còn ${room.availableRooms} phòng trống theo cơ sở dữ liệu!',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 18),

                // Pricing Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (room.originalPrice != null && room.originalPrice! > room.price)
                          Text(
                            '${_currencyFormatter.format(room.originalPrice)} VND',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        Text(
                          '${_currencyFormatter.format(room.price)} VND',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF003580),
                          ),
                        ),
                        const Text(
                          'Giá niêm yết (chưa gồm thuế & phí)',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),

                    // Action Button
                    if (isCapacityExceeded)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCBD5E1),
                          foregroundColor: const Color(0xFF64748B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () {
                          showHomeSnackBar(
                            context,
                            'Không được cho phép booking $guestsPerRoom người vào phòng này! Phòng tối đa ${capDetails.maxCapacity} người.',
                          );
                        },
                        child: Text(
                          'Quá sức chứa ($guestsPerRoom/${capDetails.maxCapacity})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                        label: const Text(
                          'Chọn phòng này',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006CE4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () {
                          ref
                              .read(hotelDetailProvider(widget.hotelId).notifier)
                              .selectRoomForBooking(room);
                        },
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

  Widget _buildSpecRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(HotelDetailModel hotel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đánh giá từ khách hàng (${hotel.reviews.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF003580),
                    ),
                  ),
                  const Text(
                    'Truy xuất từ bảng t_review trong cơ sở dữ liệu',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF003580),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hotel.starRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hotel.reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Chưa có đánh giá nào được ghi nhận trong cơ sở dữ liệu.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hotel.reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final rev = hotel.reviews[index];
                final initial = (rev.guestName.isNotEmpty ? rev.guestName[0] : 'K').toUpperCase();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF003580),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rev.guestName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                rev.createdAt != null
                                    ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(rev.createdAt!) ?? DateTime.now())
                                    : 'Khách đã lưu trú',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${rev.score.toStringAsFixed(1)} / 10',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003580),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${rev.comment}"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(HotelDetailModel hotel, num lowestPrice) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giá chỉ từ',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  Text(
                    '${_currencyFormatter.format(lowestPrice > 0 ? lowestPrice : 1200000)} VND',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003580),
                    ),
                  ),
                  const Text(
                    '/ đêm',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006CE4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                onPressed: _scrollToRooms,
                child: const Text(
                  'Chọn phòng ngay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
