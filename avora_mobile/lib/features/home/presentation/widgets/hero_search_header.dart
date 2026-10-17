import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';
import '../providers/home_provider.dart';
import 'guest_room_picker_sheet.dart';

/// Hero banner kèm hộp tìm kiếm (điểm đến, ngày, khách & phòng).
class HeroSearchHeader extends ConsumerStatefulWidget {
  const HeroSearchHeader({super.key});

  @override
  ConsumerState<HeroSearchHeader> createState() => _HeroSearchHeaderState();
}

class _HeroSearchHeaderState extends ConsumerState<HeroSearchHeader> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final dateFormat = DateFormat('dd/MM');
    final checkInStr = dateFormat.format(state.checkIn);
    final checkOutStr = dateFormat.format(state.checkOut);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      decoration: const BoxDecoration(
        color: Color(0xFF003580),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: Color(0xFFFBBE08), size: 15),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Cam kết giá tốt nhất thị trường Việt Nam',
                    style: TextStyle(
                      color: Color(0xFFFBBE08),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tìm chỗ nghỉ tiếp theo tại Việt Nam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tìm ưu đãi khách sạn đẳng cấp, phòng nghỉ tiện nghi với mức giá đặc quyền dành cho bạn.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Search Box Card (3px #FFC107 border matching Web)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFC107), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    'BẠN MUỐN ĐẾN ĐÂU?',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                TextField(
                  controller: _destinationController,
                  onChanged: (val) =>
                      ref.read(homeProvider.notifier).setDestination(val),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF003580),
                      size: 21,
                    ),
                    hintText: 'Bạn muốn đến đâu? (Đà Nẵng, Phú Quốc...)',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    suffixIcon: _destinationController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _destinationController.clear();
                              ref.read(homeProvider.notifier).setDestination('');
                            },
                          )
                        : null,
                  ),
                ),
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                InkWell(
                  onTap: () => _pickDateRange(context, state),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF003580),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NGÀY NHẬN PHÒNG – NGÀY TRẢ PHÒNG',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$checkInStr – $checkOutStr (${state.nights} đêm)',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            '${state.nights} đêm',
                            style: const TextStyle(
                              color: Color(0xFF003580),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                InkWell(
                  onTap: () => showGuestRoomPicker(context, ref, state),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: Color(0xFF003580),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SỐ KHÁCH VÀ PHÒNG',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${state.adults} người lớn · ${state.children} trẻ em · ${state.rooms} phòng',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                    label: const Text(
                      'Tìm kiếm khách sạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      final searchParams = HotelSearchParams(
                        destination: state.destination,
                        checkIn: state.checkIn,
                        checkOut: state.checkOut,
                        adults: state.adults,
                        children: state.children,
                        rooms: state.rooms,
                      );
                      context.push(AppRoutes.hotelSearch, extra: searchParams);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, HomeState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: state.checkIn,
        end: state.checkOut,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003580),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(homeProvider.notifier).setDates(picked.start, picked.end);
    }
  }
}
