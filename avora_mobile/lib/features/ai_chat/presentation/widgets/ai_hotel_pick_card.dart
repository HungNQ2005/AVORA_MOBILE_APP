import 'package:flutter/material.dart';
import 'package:avora_mobile/features/home/presentation/widgets/home_helpers.dart';
import '../../data/models/ai_chat_models.dart';

/// Thẻ phương án khách sạn do AI đề xuất.
class AiHotelPickCard extends StatelessWidget {
  final AiHotelPick pick;

  const AiHotelPickCard({super.key, required this.pick});

  Color get _badgeColor => switch (pick.badgeKey) {
        'optimal' => const Color(0xFF059669),
        'saving' => const Color(0xFF0284C7),
        'upgrade' => const Color(0xFF7C3AED),
        _ => const Color(0xFF475569),
      };

  String _vnd(num n) => '${homeCurrencyFormatter.format(n.round())}đ';

  @override
  Widget build(BuildContext context) {
    final h = pick.hotel;
    final imageSrc = h.thumbnail?.isNotEmpty == true
        ? h.thumbnail!
        : (h.images.isNotEmpty ? h.images.first : null);
    final hasDiscount = h.originalPrice != null && h.originalPrice! > h.price;
    final overBudget = pick.budgetNote?.startsWith('Vượt') == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _badgeColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: _badgeColor,
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${pick.badgeLabel} • ${pick.matchPercent}% PHÙ HỢP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image
          Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: imageSrc == null
                    ? Container(
                        color: const Color(0xFFCBD5E1),
                        child: const Icon(Icons.hotel, size: 40, color: Colors.white),
                      )
                    : Image.network(
                        imageSrc,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFCBD5E1),
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 3),
                      Text(
                        '${h.starQuality} sao',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        h.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          h.scoreLabel,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A)),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003580),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            h.starRating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 13, color: Color(0xFF0284C7)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        h.address ?? h.cityName ?? 'Việt Nam',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),

                if (pick.roomName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF0F172A)),
                            children: [
                              const TextSpan(
                                text: 'Hạng phòng: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7)),
                              ),
                              TextSpan(text: pick.roomName),
                            ],
                          ),
                        ),
                        if (pick.bedType != null || pick.roomSize != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              [pick.bedType, pick.roomSize]
                                  .whereType<String>()
                                  .where((e) => e.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF475569)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                if (pick.perks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: pick.perks
                        .map(
                          (p) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 12, color: Color(0xFF059669)),
                                const SizedBox(width: 4),
                                Text(
                                  p,
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF065F46),
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              _vnd(h.originalPrice!),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _vnd(h.price),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF003580),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' /đêm',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Tổng ${_vnd(pick.totalPrice)} cho ${pick.nights} đêm'
                            '${pick.rooms > 1 ? ' · ${pick.rooms} phòng' : ''}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pick.budgetNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          overBudget ? Icons.trending_up : Icons.savings_outlined,
                          size: 14,
                          color: overBudget
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pick.budgetNote!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: overBudget
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003580),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => showHomeSnackBar(context,
                        'Trang chi tiết & đặt phòng của ${h.name} sẽ sớm có.'),
                    label: const Text(
                      'Xem phòng & Đặt ngay',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.arrow_forward,
                        size: 16, color: Colors.white),
                    iconAlignment: IconAlignment.end,
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
