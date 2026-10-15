import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/home/presentation/providers/home_provider.dart';

import '../../data/models/hotel_detail_model.dart';
import '../../data/models/room_capacity_helper.dart';
import '../providers/hotel_detail_provider.dart';
import '../widgets/hotel_detail_lightbox.dart';

class HotelDetailScreen extends ConsumerStatefulWidget {
  final String hotelId;

  const HotelDetailScreen({super.key, required this.hotelId});

  @override
  ConsumerState<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends ConsumerState<HotelDetailScreen> {
  static const _blue = Color(0xFF155EEF);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF667085);
  static const _page = Color(0xFFF5F7FA);

  final _roomsKey = GlobalKey();
  final _currency = NumberFormat('#,###', 'vi_VN');
  late final PageController _galleryController;
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _showGallery(HotelDetailModel hotel, List<String> images) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: HotelDetailLightbox(
          images: images,
          initialIndex: _galleryIndex,
          hotelName: hotel.name,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<void> _shareHotel(HotelDetailModel hotel) async {
    await Clipboard.setData(
      ClipboardData(text: 'https://avora.vn/hotels/${hotel.hotelId}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết khách sạn')),
    );
  }

  void _scrollToRooms() {
    final sectionContext = _roomsKey.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelDetailProvider(widget.hotelId));
    final notifier = ref.read(hotelDetailProvider(widget.hotelId).notifier);
    final hotel = state.hotel;

    if (hotel == null) {
      return Scaffold(
        backgroundColor: _page,
        appBar: AppBar(
          title: const Text('Chi tiết khách sạn'),
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: state.isLoading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang tải thông tin khách sạn...'),
                    ],
                  )
                : _LoadError(
                    message: state.errorMessage ?? 'Không tìm thấy khách sạn.',
                    onRetry: notifier.loadHotelDetail,
                  ),
          ),
        ),
      );
    }

    final images = hotel.images.isNotEmpty
        ? hotel.images
        : (hotel.thumbnail == null || hotel.thumbnail!.isEmpty
              ? const <String>[]
              : <String>[hotel.thumbnail!]);
    final isFavorite = ref
        .watch(homeProvider)
        .favorites
        .contains(hotel.hotelId);
    final lowestPrice = hotel.rooms.isEmpty
        ? null
        : hotel.rooms.map((room) => room.price).reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        title: Text(
          hotel.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
        ),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
            onPressed: notifier.toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFE5484D) : _ink,
            ),
          ),
          IconButton(
            tooltip: 'Chia sẻ',
            onPressed: () => _shareHotel(hotel),
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.loadHotelDetail,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (state.errorMessage != null)
              MaterialBanner(
                content: Text(
                  'Không thể làm mới dữ liệu: ${state.errorMessage}',
                ),
                leading: const Icon(Icons.cloud_off_outlined),
                actions: [
                  TextButton(
                    onPressed: notifier.loadHotelDetail,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            _buildGallery(hotel, images),
            _buildOverview(hotel),
            _buildDescription(hotel),
            _buildFacilities(hotel),
            _buildLocation(hotel),
            _buildRooms(hotel, state, key: _roomsKey),
            _buildReviews(hotel),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(lowestPrice, hotel.rooms.isNotEmpty),
    );
  }

  Widget _buildGallery(HotelDetailModel hotel, List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 220,
        color: const Color(0xFFE9EEF5),
        child: const Icon(Icons.hotel_outlined, size: 64, color: _muted),
      );
    }

    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _galleryController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _galleryIndex = index),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _showGallery(hotel, images),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE9EEF5),
                  child: Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _galleryIndex ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _galleryIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showGallery(hotel, images),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Text(
                    '${_galleryIndex + 1}/${images.length} ảnh',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(HotelDetailModel hotel) {
    final stars = hotel.starQuality.clamp(0, 5).toInt();
    final address = hotel.fullAddress.isNotEmpty
        ? hotel.fullAddress
        : hotel.address;

    return _CardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stars > 0)
            Row(
              children: List.generate(
                stars,
                (_) =>
                    const Icon(Icons.star, color: Color(0xFFF5A623), size: 18),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            hotel.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: _blue, size: 19),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(color: _muted, height: 1.4),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  hotel.starRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.scoreLabel,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${hotel.reviewsCount} đánh giá',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(HotelDetailModel hotel) {
    if (hotel.description.trim().isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Giới thiệu',
      icon: Icons.subject_outlined,
      child: Text(
        hotel.description.trim(),
        style: const TextStyle(color: _muted, height: 1.55),
      ),
    );
  }

  Widget _buildFacilities(HotelDetailModel hotel) {
    if (hotel.facilities.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Tiện nghi',
      icon: Icons.spa_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: hotel.facilities
            .map(
              (facility) => Chip(
                avatar: Icon(
                  _facilityIcon(facility.type, facility.name),
                  size: 17,
                  color: _blue,
                ),
                label: Text(facility.name),
                backgroundColor: const Color(0xFFF3F6FB),
                side: BorderSide.none,
                labelStyle: const TextStyle(color: _ink, fontSize: 12),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLocation(HotelDetailModel hotel) {
    final address = hotel.fullAddress.isNotEmpty
        ? hotel.fullAddress
        : hotel.address;
    if (address.isEmpty && hotel.lat == null && hotel.lng == null) {
      return const SizedBox.shrink();
    }
    return _Section(
      title: 'Vị trí',
      icon: Icons.place_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty)
            Text(address, style: const TextStyle(color: _muted, height: 1.45)),
          if (hotel.lat != null && hotel.lng != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tọa độ: ${hotel.lat!.toStringAsFixed(5)}, '
              '${hotel.lng!.toStringAsFixed(5)}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRooms(
    HotelDetailModel hotel,
    HotelDetailState state, {
    required Key key,
  }) {
    return _Section(
      key: key,
      title: 'Phòng & giá',
      icon: Icons.bed_outlined,
      subtitle:
          '${state.formattedStayDates} · ${state.adults} người lớn'
          '${state.children > 0 ? ' · ${state.children} trẻ em' : ''}'
          ' · ${state.rooms} phòng',
      child: hotel.rooms.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Khách sạn chưa có thông tin phòng cho thời gian đã chọn.',
                style: TextStyle(color: _muted),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < hotel.rooms.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  _RoomCard(room: hotel.rooms[index], currency: _currency),
                ],
              ],
            ),
    );
  }

  Widget _buildReviews(HotelDetailModel hotel) {
    return _Section(
      title: 'Đánh giá của khách',
      icon: Icons.rate_review_outlined,
      subtitle: '${hotel.reviewsCount} đánh giá · ${hotel.starRating}/10',
      child: hotel.reviews.isEmpty
          ? const Text(
              'Chưa có đánh giá nào cho khách sạn này.',
              style: TextStyle(color: _muted),
            )
          : Column(
              children: [
                for (var index = 0; index < hotel.reviews.length; index++) ...[
                  if (index > 0) const Divider(height: 24),
                  _ReviewTile(review: hotel.reviews[index]),
                ],
              ],
            ),
    );
  }

  Widget _buildBottomBar(num? lowestPrice, bool hasRooms) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lowestPrice == null
                          ? 'Chưa có giá phòng'
                          : 'Từ ${_currency.format(lowestPrice)} đ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'giá mỗi đêm theo dữ liệu hiện có',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: hasRooms ? _scrollToRooms : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Xem phòng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _facilityIcon(String? type, String name) {
    final value = '${type ?? ''} $name'.toLowerCase();
    if (value.contains('pool') ||
        value.contains('bể bơi') ||
        value.contains('hồ bơi')) {
      return Icons.pool_outlined;
    }
    if (value.contains('wifi') || value.contains('internet')) {
      return Icons.wifi;
    }
    if (value.contains('breakfast') ||
        value.contains('nhà hàng') ||
        value.contains('ăn sáng')) {
      return Icons.restaurant_outlined;
    }
    if (value.contains('spa') || value.contains('massage')) {
      return Icons.spa_outlined;
    }
    if (value.contains('gym') || value.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (value.contains('parking') || value.contains('đỗ xe')) {
      return Icons.local_parking_outlined;
    }
    return Icons.check_circle_outline;
  }
}

class _RoomCard extends StatelessWidget {
  final RoomTypeDetailModel room;
  final NumberFormat currency;

  const _RoomCard({required this.room, required this.currency});

  @override
  Widget build(BuildContext context) {
    final capacity = RoomCapacityHelper.getRoomCapacityDetails(
      bedType: room.bedType,
      maxAdults: room.maxAdults,
      maxChildren: room.maxChildren,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                room.availableRooms > 0
                    ? 'Còn ${room.availableRooms}'
                    : 'Hết phòng',
                style: TextStyle(
                  color: room.availableRooms > 0
                      ? const Color(0xFF16834B)
                      : const Color(0xFFD92D20),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (room.image != null && room.image!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                room.image!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (room.bedType != null && room.bedType!.isNotEmpty)
            _RoomDetailLine(icon: Icons.bed_outlined, text: room.bedType!),
          if (room.roomSize != null && room.roomSize!.isNotEmpty)
            _RoomDetailLine(
              icon: Icons.open_in_full,
              text: 'Diện tích ${room.roomSize}',
            ),
          _RoomDetailLine(
            icon: Icons.people_outline,
            text: 'Tối đa ${capacity.maxCapacity} khách',
          ),
          _RoomDetailLine(
            icon: room.availableRooms > 0
                ? Icons.check_circle_outline
                : Icons.info_outline,
            text: room.availableRooms > 0
                ? 'Còn ${room.availableRooms} phòng theo tồn kho'
                : 'Hiện không còn phòng theo tồn kho',
          ),
          if (room.policyDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              room.policyDescription,
              style: const TextStyle(color: Color(0xFF16834B), fontSize: 12),
            ),
          ],
          const Divider(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (room.originalPrice != null &&
                      room.originalPrice! > room.price)
                    Text(
                      '${currency.format(room.originalPrice)} đ',
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    '${currency.format(room.price)} đ',
                    style: const TextStyle(
                      color: Color(0xFF155EEF),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'mỗi đêm',
                    style: TextStyle(color: Color(0xFF667085), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomDetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RoomDetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF667085)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF475467), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt == null
        ? null
        : DateTime.tryParse(review.createdAt!);
    final initial = review.guestName.trim().isEmpty
        ? 'K'
        : review.guestName.trim().substring(0, 1).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFEAF1FF),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF155EEF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.guestName,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (date != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(date),
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review.score.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF155EEF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            review.comment,
            style: const TextStyle(color: Color(0xFF475467), height: 1.45),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;

  const _Section({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF155EEF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final Widget child;

  const _CardSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: child,
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: Color(0xFFD92D20),
          size: 48,
        ),
        const SizedBox(height: 12),
        const Text(
          'Không tải được thông tin khách sạn',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF667085)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      ],
    );
  }
}
