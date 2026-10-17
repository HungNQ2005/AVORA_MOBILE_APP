import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';
import 'home_helpers.dart';

/// Banner giới thiệu bản đồ du lịch tương tác chuyển thể từ .avora-map-card trên Web.
class InteractiveMapBanner extends StatelessWidget {
  const InteractiveMapBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          size: 15,
                          color: Color(0xFF0066FF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'BẢN ĐỒ DU LỊCH TƯƠNG TÁC',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0066FF),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tìm khách sạn trên bản đồ địa phương',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dễ dàng định vị các khách sạn sát biển, gần trung tâm thương mại hoặc danh lam thắng cảnh tại Việt Nam.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=300&q=80',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 96,
                        height: 96,
                        color: const Color(0xFFEFF6FF),
                        child: const Icon(
                          Icons.map_rounded,
                          color: Color(0xFF003580),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0066FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              _CityMapChip(
                label: 'Đà Nẵng (1.840+)',
                city: 'Đà Nẵng',
              ),
              _CityMapChip(
                label: 'Hà Nội (2.400+)',
                city: 'Hà Nội',
              ),
              _CityMapChip(
                label: 'Phú Quốc (950+)',
                city: 'Phú Quốc',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF003580),
                side: const BorderSide(color: Color(0xFF003580), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.map_outlined, size: 17),
              label: const Text(
                'Mở xem bản đồ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                showHomeSnackBar(context, 'Tính năng Bản đồ đang mở...');
                context.push(AppRoutes.hotelSearch);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CityMapChip extends StatelessWidget {
  final String label;
  final String city;

  const _CityMapChip({required this.label, required this.city});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        final now = DateTime.now();
        context.push(
          AppRoutes.hotelSearch,
          extra: HotelSearchParams(
            destination: city,
            checkIn: now.add(const Duration(days: 1)),
            checkOut: now.add(const Duration(days: 3)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 13,
              color: Color(0xFF0066FF),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
