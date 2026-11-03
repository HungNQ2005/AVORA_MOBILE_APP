import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../data/models/hotel_model.dart';
import '../providers/home_provider.dart';
import 'home_helpers.dart';

/// Thẻ khách sạn trong danh sách được yêu thích.
class HotelCard extends ConsumerWidget {
  final HotelModel hotel;
  final bool isFavorite;

  const HotelCard({super.key, required this.hotel, required this.isFavorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageSrc = [hotel.thumbnail, ...hotel.images]
      .whereType<String>()
      .map((image) => image.trim())
      .firstWhere((image) => image.isNotEmpty, orElse: () => '');

    final oldPrice = (hotel.price * 1.18).round();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(AppRoutes.hotelDetailPath(hotel.hotelId)),
      child: Container(
        width: 245,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: imageSrc.isEmpty
                      ? _buildImageFallback()
                      : Image.network(
                          imageSrc,
                          height: 126,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildImageFallback(),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(homeProvider.notifier)
                          .toggleFavorite(hotel.hotelId);
                      showHomeSnackBar(
                        context,
                        isFavorite
                            ? 'Đã xóa ${hotel.name} khỏi yêu thích'
                            : 'Đã lưu ${hotel.name} vào yêu thích',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color:
                            isFavorite ? const Color(0xFFFF4D4F) : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                if (hotel.isGenius || hotel.tag != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003580),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hotel.isGenius ? 'Genius' : (hotel.tag ?? ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        hotel.starQuality.clamp(1, 5),
                        (i) => const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFFFC107),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            hotel.address ?? hotel.cityName ?? 'Việt Nam',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003580),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hotel.starRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hotel.scoreLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '· ${hotel.reviewsCount} đánh giá',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${homeCurrencyFormatter.format(oldPrice)}đ',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${homeCurrencyFormatter.format(hotel.price)} VND',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'đã bao gồm thuế và phí',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => context.push(
                          AppRoutes.hotelDetailPath(hotel.hotelId),
                        ),
                        child: const Text(
                          'Xem phòng trống',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 126,
      width: double.infinity,
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.apartment_rounded,
        color: Color(0xFF003580),
        size: 36,
      ),
    );
  }
}
