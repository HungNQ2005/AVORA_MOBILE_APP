import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';

final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

/// Thẻ hiển thị khách sạn trong danh sách tìm kiếm, chuyển thể chuẩn mực từ HotelCard.jsx của AVORA Web.
class HotelSearchCard extends StatelessWidget {
  final HotelModel hotel;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;
  final int nights;
  final int guests;

  const HotelSearchCard({
    super.key,
    required this.hotel,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
    this.nights = 2,
    this.guests = 2,
  });

  @override
  Widget build(BuildContext context) {
    final imageSrc =
        hotel.thumbnail ??
        (hotel.images.isNotEmpty ? hotel.images.first : null) ??
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80';

    final starCount = hotel.starQuality.clamp(1, 5);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. Image Header ──────────────────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageSrc,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Color(0xFF94A3B8),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Heart Favorite Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: onToggleFavorite,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? const Color(0xFFEF4444)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Bottom Tag (Summer discount / flash deal)
                if (hotel.tag != null && hotel.tag!.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003580).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFFB700),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_offer,
                            color: Color(0xFFFFB700),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hotel.tag!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ─── 2. Content Body ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Stars + Genius VIP + Score Block
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stars and Genius VIP
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 4,
                          children: [
                            ...List.generate(
                              starCount,
                              (index) => const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: Color(0xFFFFC107),
                              ),
                            ),
                            if (hotel.isGenius) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Genius VIP',
                                  style: TextStyle(
                                    color: Color(0xFF00224F),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Review Score Block (Top Right)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hotel.scoreLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003580),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hotel.starRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_currencyFormatter.format(hotel.reviewsCount)} đánh giá',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Hotel Name
                  Text(
                    hotel.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003580),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Location Pin + Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFF006CE4),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.address ?? hotel.cityName ?? 'Việt Nam',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF006CE4),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF006CE4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Highlighted Room Box
                  if (hotel.roomHighlight != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotel.roomHighlight!.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${hotel.roomHighlight!.bedType} · ${hotel.roomHighlight!.roomSize}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Amenities / Features List (Vertical bullets with green checks)
                  ...hotel.facilities
                      .take(2)
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  f.name,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  // Cancellation policy
                  if (hotel.cancellationPolicy != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hotel.cancellationPolicy!.description,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Urgency: available rooms <= 5
                  if (hotel.availableRooms != null &&
                      hotel.availableRooms! > 0 &&
                      hotel.availableRooms! <= 5)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Color(0xFFD93025),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Còn ${hotel.availableRooms} phòng với mức giá này',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFD93025),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 16, color: Color(0xFFE2E8F0)),

                  // ─── 3. Pricing & Booking CTA ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Stay info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$nights đêm, $guests người lớn',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Bao gồm bữa sáng',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price block
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hotel.originalPrice != null &&
                              hotel.originalPrice! > hotel.price)
                            Text(
                              '${_currencyFormatter.format(hotel.originalPrice)} VND',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Color(0xFFDC2626),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            '${_currencyFormatter.format(hotel.price)} VND',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            'Đã bao gồm thuế & phí',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Xem phòng trống',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
