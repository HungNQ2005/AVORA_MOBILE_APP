import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_provider.dart';
import 'hotel_card.dart';

/// Section khách sạn được yêu thích nhất (dữ liệu từ database).
class FavoriteHotelsSection extends ConsumerWidget {
  const FavoriteHotelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ĐƯỢC ĐẶT NHIỀU NHẤT 24 GIỜ QUA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Chỗ nghỉ được khách yêu thích nhất',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.hotels.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Không tìm thấy khách sạn nào.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          SizedBox(
            height: 310,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.hotels.length,
              itemBuilder: (context, index) {
                final hotel = state.hotels[index];
                final isFav = state.favorites.contains(hotel.hotelId);
                return HotelCard(hotel: hotel, isFavorite: isFav);
              },
            ),
          ),
      ],
    );
  }
}
