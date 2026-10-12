import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';

final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

/// Modal hiển thị bản đồ khách sạn tương tác, đồng bộ với MapModal.jsx trên AVORA Web.
class HotelMapModal extends StatefulWidget {
  final List<HotelModel> hotels;
  final String destination;
  final int nights;
  final int guests;
  final void Function(HotelModel hotel)? onSelectHotel;

  const HotelMapModal({
    super.key,
    required this.hotels,
    this.destination = 'Việt Nam',
    this.nights = 2,
    this.guests = 2,
    this.onSelectHotel,
  });

  static Future<void> show(
    BuildContext context, {
    required List<HotelModel> hotels,
    String destination = 'Việt Nam',
    int nights = 2,
    int guests = 2,
    void Function(HotelModel hotel)? onSelectHotel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: HotelMapModal(
          hotels: hotels,
          destination: destination,
          nights: nights,
          guests: guests,
          onSelectHotel: onSelectHotel,
        ),
      ),
    );
  }

  @override
  State<HotelMapModal> createState() => _HotelMapModalState();
}

class _HotelMapModalState extends State<HotelMapModal> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeHotel = widget.hotels.isNotEmpty && _selectedIndex < widget.hotels.length
        ? widget.hotels[_selectedIndex]
        : null;

    final destName = widget.destination.isNotEmpty ? widget.destination : 'Việt Nam';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ─── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Color(0xFF003580), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bản đồ khách sạn tại $destName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hiển thị ${widget.hotels.length} chỗ nghỉ có sẵn trong khu vực',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Đóng bản đồ',
                ),
              ],
            ),
          ),

          // ─── Interactive Map Area ──────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Stylized map background
                Container(
                  color: const Color(0xFFE0F2FE),
                  child: CustomPaint(
                    painter: _MapCanvasPainter(),
                    size: Size.infinite,
                  ),
                ),

                // Map Pin Markers
                if (widget.hotels.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final count = widget.hotels.length;
                      return Stack(
                        children: List.generate(count, (index) {
                          final h = widget.hotels[index];
                          final isSelected = index == _selectedIndex;

                          // Distribute pins across the map area
                          final xFactor = 0.15 + (index % 4) * 0.22;
                          final yFactor = 0.18 + ((index * 3) % 7) * 0.09;
                          final left = constraints.maxWidth * xFactor;
                          final top = constraints.maxHeight * yFactor;

                          final priceK = (h.price / 1000).round();

                          return Positioned(
                            left: left - 40,
                            top: top - 20,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedIndex = index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF003580)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFB700)
                                        : const Color(0xFF003580),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hotel,
                                      size: 13,
                                      color: isSelected
                                          ? const Color(0xFFFFB700)
                                          : const Color(0xFF003580),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${priceK}k',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),

                // Selected Hotel Bottom Floating Card
                if (activeHotel != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  activeHotel.thumbnail ??
                                      (activeHotel.images.isNotEmpty
                                          ? activeHotel.images.first
                                          : ''),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(Icons.hotel,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ...List.generate(
                                          activeHotel.starQuality.clamp(1, 5),
                                          (i) => const Icon(Icons.star,
                                              size: 12, color: Color(0xFFF59E0B)),
                                        ),
                                        if (activeHotel.isGenius) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFB700),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: const Text(
                                              'GENIUS VIP',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF00224F),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF003580),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            activeHotel.starRating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      activeHotel.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activeHotel.address ??
                                          activeHotel.cityName ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_currencyFormatter.format(activeHotel.price)} VND',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF003580),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 36,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003580),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onSelectHotel?.call(activeHotel);
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Xem phòng trống',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    // Coastline path
    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
          size.width * 0.4, size.height * 0.4, size.width * 0.7, size.height * 0.1)
      ..lineTo(size.width, size.height * 0.15)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, landPaint);

    // Grid lines for roads
    final roadPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.0;

    for (double y = size.height * 0.3; y < size.height; y += 70) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 40; x < size.width; x += 80) {
      canvas.drawLine(
          Offset(x, size.height * 0.25), Offset(x, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
