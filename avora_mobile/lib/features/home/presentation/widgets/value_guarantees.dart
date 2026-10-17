import 'package:flutter/material.dart';
import 'home_helpers.dart';

/// Các cam kết giá trị của Avora (.avora-features-grid) + Footer đồng bộ với bản Website.
class ValueGuarantees extends StatelessWidget {
  const ValueGuarantees({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Column(
            children: [
              _GuaranteeRow(
                icon: Icons.savings_outlined,
                title: 'Giá tốt không phí ẩn',
                desc:
                    'Mọi mức giá phòng hiển thị đều minh bạch thuế phí rõ ràng cho khách hàng tại Việt Nam.',
              ),
              Divider(height: 22, color: Color(0xFFE5E7EB)),
              _GuaranteeRow(
                icon: Icons.support_agent,
                title: 'Hỗ trợ tiếng Việt 24/7',
                desc:
                    'Đội ngũ chăm sóc người Việt luôn sẵn sàng giải đáp và xử lý thay đổi đặt phòng qua hotline.',
              ),
              Divider(height: 22, color: Color(0xFFE5E7EB)),
              _GuaranteeRow(
                icon: Icons.verified_user_outlined,
                title: 'Xác nhận đặt phòng tức thì',
                desc:
                    'Nhận ngay voucher điện tử kèm mã QR check-in nhanh chóng tại quầy lễ tân khách sạn.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Web Footer Newsletter Banner (#003580)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          color: const Color(0xFF003580),
          child: Column(
            children: [
              const Text(
                'Tiết kiệm thời gian, tiết kiệm tiền bạc!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Đăng ký nhận bản tin Avora để nhận ngay ưu đãi giảm đến 15%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFDBEAFE),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Địa chỉ e-mail của bạn',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => showHomeSnackBar(
                        context,
                        'Đã đăng ký nhận bản tin ưu đãi Avora!',
                      ),
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Web Footer Info (#F2F4F7)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          color: const Color(0xFFF2F4F7),
          child: const Column(
            children: [
              Text(
                'Avora.com là nền tảng đặt phòng trực tuyến hàng đầu dành cho du khách tại Việt Nam.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF4B5563),
                ),
              ),
              SizedBox(height: 6),
              Text(
                '© 2024 Avora™. Bảo lưu mọi quyền.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF003580), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
