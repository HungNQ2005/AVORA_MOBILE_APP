import 'package:flutter/material.dart';

/// Các cam kết giá trị của Avora.
class ValueGuarantees extends StatelessWidget {
  const ValueGuarantees({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          _GuaranteeRow(
            icon: Icons.savings_outlined,
            title: 'Giá tốt không phí ẩn',
            desc: 'Mọi giá phòng hiển thị đều minh bạch thuế phí rõ ràng.',
          ),
          Divider(height: 20),
          _GuaranteeRow(
            icon: Icons.support_agent,
            title: 'Hỗ trợ tiếng Việt 24/7',
            desc: 'Đội ngũ chăm sóc luôn sẵn sàng giải đáp và xử lý đặt phòng.',
          ),
          Divider(height: 20),
          _GuaranteeRow(
            icon: Icons.flash_on,
            title: 'Xác nhận đặt phòng tức thì',
            desc: 'Nhận ngay voucher điện tử kèm mã QR check-in tại quầy lễ tân.',
          ),
        ],
      ),
    );
  }
}

class _GuaranteeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _GuaranteeRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0284C7), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
