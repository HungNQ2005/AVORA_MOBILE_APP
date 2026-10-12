import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_provider.dart';

/// Mở bottom sheet chọn số lượng khách và phòng.
void showGuestRoomPicker(BuildContext context, WidgetRef ref, HomeState state) {
  int tempAdults = state.adults;
  int tempChildren = state.children;
  int tempRooms = state.rooms;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số lượng khách và phòng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tối đa 5 người/phòng (bao gồm cả giường phụ).',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // Adults
                _CounterRow(
                  title: 'Người lớn',
                  subtitle: 'Từ 18 tuổi trở lên',
                  value: tempAdults,
                  minValue: 1,
                  onChanged: (val) {
                    setModalState(() {
                      tempAdults = val;
                      final minRooms = ((tempAdults + tempChildren) / 5).ceil();
                      if (tempRooms < minRooms) tempRooms = minRooms;
                    });
                  },
                ),
                const Divider(),

                // Children
                _CounterRow(
                  title: 'Trẻ em',
                  subtitle: '0 – 17 tuổi',
                  value: tempChildren,
                  minValue: 0,
                  onChanged: (val) {
                    setModalState(() {
                      tempChildren = val;
                      final minRooms = ((tempAdults + tempChildren) / 5).ceil();
                      if (tempRooms < minRooms) tempRooms = minRooms;
                    });
                  },
                ),
                const Divider(),

                // Rooms
                _CounterRow(
                  title: 'Phòng',
                  subtitle: 'Số lượng phòng cần đặt',
                  value: tempRooms,
                  minValue: ((tempAdults + tempChildren) / 5).ceil(),
                  onChanged: (val) => setModalState(() => tempRooms = val),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003580),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ref.read(homeProvider.notifier).setGuestsAndRooms(
                            adults: tempAdults,
                            children: tempChildren,
                            rooms: tempRooms,
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Áp dụng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _CounterRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final int minValue;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.minValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: value > minValue ? const Color(0xFF0284C7) : Colors.grey,
              onPressed: value > minValue ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: const Color(0xFF0284C7),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}
