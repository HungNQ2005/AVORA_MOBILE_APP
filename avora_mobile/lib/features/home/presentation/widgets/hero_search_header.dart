import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/home_provider.dart';
import 'guest_room_picker_sheet.dart';
import 'home_helpers.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
          // Guarantee Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Color(0xFFFBBF24), size: 14),
                SizedBox(width: 6),
                Text(
                  'Cam kết giá tốt nhất thị trường Việt Nam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ưu đãi khách sạn đẳng cấp với giá đặc quyền dành cho bạn.',
            style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Search Box Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFBBF24), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Field 1: Điểm đến
                TextField(
                  controller: _destinationController,
                  onChanged: (val) =>
                      ref.read(homeProvider.notifier).setDestination(val),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.location_on, color: Color(0xFF0284C7)),
                    hintText: 'Bạn muốn đến đâu? (Đà Nẵng, Phú Quốc...)',
                    hintStyle: const TextStyle(fontSize: 13),
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
                const Divider(height: 1),

                // Field 2: Chọn Ngày
                InkWell(
                  onTap: () => _pickDateRange(context, state),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF0284C7), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$checkInStr – $checkOutStr (${state.nights} đêm)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${state.nights} đêm',
                            style: const TextStyle(
                              color: Color(0xFF0284C7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Field 3: Số khách & Số phòng
                InkWell(
                  onTap: () => showGuestRoomPicker(context, ref, state),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline,
                            color: Color(0xFF0284C7), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${state.adults} người lớn · ${state.children} trẻ em · ${state.rooms} phòng',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Nút Tìm Kiếm
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003580),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text(
                      'Tìm kiếm khách sạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      final dest = state.destination.isEmpty
                          ? 'toàn quốc'
                          : state.destination;
                      showHomeSnackBar(context,
                          'Đang tìm khách sạn tại $dest (${state.nights} đêm, ${state.adults} khách)...');
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
