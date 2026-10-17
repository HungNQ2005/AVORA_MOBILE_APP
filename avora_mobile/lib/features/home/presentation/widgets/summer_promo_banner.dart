import 'package:flutter/material.dart';
import 'home_helpers.dart';

/// Banner khuyến mãi mùa hè.
class SummerPromoBanner extends StatelessWidget {
  const SummerPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF002255),
            Color(0xFF003580),
            Color(0xFF0052CC),
          ],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24003580),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ƯU ĐÃI MÙA HÈ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tiết kiệm tối thiểu 15%',
                style: TextStyle(
                  color: Color(0xFFFEF08A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Du ngoạn ngắm cảnh Việt Nam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tận hưởng kỳ nghỉ trong mơ từ vịnh biển Nha Trang trong xanh đến sương mờ xứ Đà Lạt ngàn hoa.',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF003580),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              minimumSize: Size.zero,
              elevation: 0,
            ),
            onPressed: () =>
                showHomeSnackBar(context, 'Đang mở danh sách ưu đãi mùa hè!'),
            child: const Text(
              'Khám phá ưu đãi ngay →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF003580),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
