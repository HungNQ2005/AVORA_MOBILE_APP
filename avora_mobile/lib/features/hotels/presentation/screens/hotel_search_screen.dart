import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';

import '../providers/hotel_search_provider.dart';
import '../widgets/hotel_filter_sheet.dart';
import '../widgets/hotel_map_modal.dart';
import '../widgets/hotel_search_card.dart';
import '../widgets/hotel_search_header_widget.dart';
import '../widgets/hotel_sort_sheet.dart';

/// Màn hình Tìm kiếm, Lọc và Sắp xếp khách sạn (Chức năng 1).
/// Thiết kế đồng bộ hoàn toàn với giao diện AVORA Web (màu chủ đạo #003580).
class HotelSearchScreen extends ConsumerStatefulWidget {
  final HotelSearchParams? initialParams;
  final String? initialDestination;

  const HotelSearchScreen({
    super.key,
    this.initialParams,
    this.initialDestination,
  });

  @override
  ConsumerState<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends ConsumerState<HotelSearchScreen> {
  static const List<Map<String, String>> _sortTabs = [
    {'id': 'popularity', 'label': 'Độ phổ biến hàng đầu'},
    {'id': 'price_asc', 'label': 'Giá thấp đến cao'},
    {'id': 'rating_price', 'label': 'Đánh giá & Giá'},
    {'id': 'beach_distance', 'label': 'Gần bãi biển nhất'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialParams != null) {
        ref
            .read(hotelSearchProvider.notifier)
            .performSearch(newParams: widget.initialParams);
      } else if (widget.initialDestination != null &&
          widget.initialDestination!.isNotEmpty) {
        ref
            .read(hotelSearchProvider.notifier)
            .setDestination(widget.initialDestination!);
      } else {
        ref.read(hotelSearchProvider.notifier).performSearch();
      }
    });
  }

  String _getSortLabel(String sortId) {
    switch (sortId) {
      case 'price_asc':
        return 'Giá thấp nhất';
      case 'rating_price':
        return 'Đánh giá & Giá';
      case 'beach_distance':
        return 'Gần biển nhất';
      case 'popularity':
      default:
        return 'Phổ biến nhất';
    }
  }

  void _openFilterSheet(
    BuildContext context,
    HotelSearchState state,
    HotelSearchNotifier notifier,
  ) {
    HotelFilterBottomSheet.show(
      context,
      initialParams: state.params,
      filterStats: state.filterStats,
      totalCount: state.total,
      onApplyFilters:
          ({
            required priceRangeKey,
            required starRatings,
            required minScore,
            required facilities,
            required capacityFilter,
            required onlyAvailable,
          }) {
            notifier.applyAllFilters(
              priceRangeKey: priceRangeKey,
              starRatings: starRatings,
              minScore: minScore,
              facilities: facilities,
              capacityFilter: capacityFilter,
              onlyAvailable: onlyAvailable,
            );
          },
      onResetFilters: () => notifier.resetFilters(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelSearchProvider);
    final notifier = ref.read(hotelSearchProvider.notifier);
    final dest = state.params.destination.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // ─── 1. Header & Search Controls ──────────────────────────────────
          HotelSearchHeaderWidget(
            params: state.params,
            onBack: () => context.pop(),
            onSearch: (updatedParams) =>
                notifier.performSearch(newParams: updatedParams),
          ),

          // Phần dưới header cuộn cùng danh sách để không chiếm chỗ trên màn hình nhỏ
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── 2. Breadcrumb Navigation Strip ───────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        color: const Color(0xFFF1F5F9),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            children: [
                              const TextSpan(
                                text: 'Trang chủ',
                                style: TextStyle(
                                  color: Color(0xFF006CE4),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: '  /  '),
                              const TextSpan(
                                text: 'Việt Nam',
                                style: TextStyle(
                                  color: Color(0xFF006CE4),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (dest.isNotEmpty &&
                                  dest.toLowerCase() != 'việt nam' &&
                                  dest.toLowerCase() != 'viet nam') ...[
                                const TextSpan(text: '  /  '),
                                TextSpan(
                                  text: dest.split(',')[0].trim(),
                                  style: const TextStyle(
                                    color: Color(0xFF006CE4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const TextSpan(text: '  /  '),
                              const TextSpan(
                                text: 'Kết quả tìm kiếm',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // ─── 3. Results Header & Map Button ───────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.isLoading
                                        ? 'Đang tìm kiếm...'
                                        : 'Tìm thấy ${state.total} chỗ nghỉ',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Giá đã hiển thị tổng cộng cho số ngày: ${state.params.nights} đêm',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: const Color(0xFF003580),
                                side: const BorderSide(
                                  color: Color(0xFF003580),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: const Text(
                                'Xem trên bản đồ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                HotelMapModal.show(
                                  context,
                                  hotels: state.hotels,
                                  destination: dest.isNotEmpty
                                      ? dest
                                      : 'Việt Nam',
                                  nights: state.params.nights,
                                  guests: state.params.totalGuests,
                                  onSelectHotel: (hotel) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Chọn khách sạn: ${hotel.name}',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF003580,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // ─── 4. Urgency Alert Banner (Amber Card) ─────────────────────────
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFD97706),
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    height: 1.35,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '19% chỗ nghỉ tại ${dest.isNotEmpty ? dest.split(',')[0].trim() : 'điểm đến này'} không còn phòng trống ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'cho ngày bạn chọn trên trang web của chúng tôi. Hãy nhanh tay đặt ngay để có mức giá tốt này!',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ─── 5. Sorting Tabs & Filter Action Bar ──────────────────────────
                      Container(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Horizontal Tabs matching Web
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: _sortTabs.map((tab) {
                                  final isSelected =
                                      state.params.sortBy == tab['id'];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InkWell(
                                      onTap: () =>
                                          notifier.setSortBy(tab['id']!),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF003580)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF003580)
                                                : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Text(
                                          tab['label']!,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Action Bar: Sort Modal Button & Filter Button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Sort Outlined Button
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: const Color(0xFF003580),
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                    ),
                                    icon: const Icon(Icons.swap_vert, size: 15),
                                    label: Text(
                                      _getSortLabel(state.params.sortBy),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () {
                                      HotelSortBottomSheet.show(
                                        context,
                                        currentSort: state.params.sortBy,
                                        onSelectSort: (newSort) =>
                                            notifier.setSortBy(newSort),
                                      );
                                    },
                                  ),

                                  // Filter Button
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor:
                                          state.params.activeFiltersCount > 0
                                          ? const Color(0xFF003580)
                                          : const Color(0xFFF8FAFC),
                                      foregroundColor:
                                          state.params.activeFiltersCount > 0
                                          ? Colors.white
                                          : const Color(0xFF003580),
                                      elevation: 0,
                                      side: BorderSide(
                                        color:
                                            state.params.activeFiltersCount > 0
                                            ? const Color(0xFF003580)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                    ),
                                    icon: const Icon(Icons.tune, size: 15),
                                    label: Text(
                                      state.params.activeFiltersCount > 0
                                          ? 'Bộ lọc (${state.params.activeFiltersCount})'
                                          : 'Bộ lọc',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () => _openFilterSheet(
                                      context,
                                      state,
                                      notifier,
                                    ),
                                  ),
                                  if (state.params.activeFiltersCount > 0) ...[
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: const Color(
                                          0xFFD93025,
                                        ),
                                      ),
                                      icon: const Icon(Icons.clear, size: 14),
                                      label: const Text(
                                        'Xóa tất cả',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () => notifier.resetFilters(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ─── 6. Hotel List or States ────────────────────────────────
              body: RefreshIndicator(
                color: const Color(0xFF003580),
                onRefresh: () => notifier.retry(),
                child: _buildBody(context, state, notifier),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HotelSearchState state,
    HotelSearchNotifier notifier,
  ) {
    // A. Loading State
    if (state.isLoading) {
      return ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, _) => _buildSkeletonCard(),
      );
    }

    // B. Capacity Exceeded Warning (> 5 guests per room)
    if (state.exceededCapacity) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vượt quá sức chứa phòng',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.capacityMessage ?? 'Sức chứa tối đa của 1 phòng là 5 người (2 giường tiêu chuẩn × 2 = 4 người, có thêm 1 giường phụ = 5 người). Vui lòng tăng thêm số phòng.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final nextRooms = state.params.minRoomsRequired;
                    notifier.setGuestsAndRooms(rooms: nextRooms);
                  },
                  child: Text(
                    'Tăng lên ${state.params.minRoomsRequired} phòng',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // C. Error State
    if (state.errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Thử lại',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => notifier.retry(),
            ),
          ),
        ],
      );
    }

    // D. Empty State
    if (state.hotels.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.hotel_outlined, size: 64, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy khách sạn phù hợp',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thử thay đổi ngày nhận/trả phòng, giảm bớt các tiêu chí lọc hoặc tìm kiếm điểm đến khác.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (state.params.activeFiltersCount > 0)
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003580),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.filter_alt_off),
                label: const Text(
                  'Xóa toàn bộ bộ lọc',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => notifier.resetFilters(),
              ),
            ),
        ],
      );
    }

    // E. Hotel List
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.hotels.length,
      itemBuilder: (context, index) {
        final hotel = state.hotels[index];
        final isFav = state.favorites.contains(hotel.hotelId);

        return HotelSearchCard(
          hotel: hotel,
          isFavorite: isFav,
          nights: state.params.nights,
          guests: state.params.totalGuests,
          onToggleFavorite: () => notifier.toggleFavorite(hotel.hotelId),
          onTap: () {
            final router = GoRouter.maybeOf(context);
            if (router != null) {
              context.push(AppRoutes.hotelDetailPath(hotel.hotelId));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chọn khách sạn: ${hotel.name}'),
                  backgroundColor: const Color(0xFF003580),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
