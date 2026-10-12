import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final imageSrc = hotel.thumbnail ??
        (hotel.images.isNotEmpty ? hotel.images.first : null) ??
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80';

    return Container(
      width: 230,
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
          // Image + Heart
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  imageSrc,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: const Color(0xFFCBD5E1),
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () {
                    ref.read(homeProvider.notifier).toggleFavorite(hotel.hotelId);
                    showHomeSnackBar(
                        context,
                        isFavorite
                            ? 'Đã xóa ${hotel.name} khỏi yêu thích'
                            : 'Đã lưu ${hotel.name} vào yêu thích');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              if (hotel.isGenius || hotel.tag != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003580),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hotel.isGenius ? 'Genius' : (hotel.tag ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Star rating icons
                Row(
                  children: List.generate(
                    hotel.starQuality,
                    (i) => const Icon(Icons.star,
                        size: 12, color: Color(0xFFFBBF24)),
                  ),
                ),
                const SizedBox(height: 4),
                // Hotel Name
                Text(
                  hotel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                // Address/City
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        hotel.address ?? hotel.cityName ?? 'Việt Nam',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Score Badge
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003580),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hotel.starRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hotel.scoreLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Price Box
                Text(
                  '${homeCurrencyFormatter.format(hotel.price)} VND',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Text(
                  'đã bao gồm thuế và phí',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
