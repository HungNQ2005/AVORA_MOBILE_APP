import 'package:flutter/material.dart';

/// Banner hỗ trợ khách hàng và đối tác 24/7 ở chân trang Quản lý Đặt Chỗ
/// Đồng bộ 1:1 với BookingSupportBanner.jsx của bản Web
class BookingSupportBanner extends StatelessWidget {
  const BookingSupportBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFF003580),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cần trợ giúp về đơn đặt phòng?',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Đội ngũ chuyên viên của Avora sẵn sàng hỗ trợ 24/7 về thủ tục nhận phòng, thay đổi ngày lưu trú và hoàn hủy.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.phone_in_talk_rounded,
                                color: Color(0xFF003580)),
                            SizedBox(width: 8),
                            Text('Tổng đài Avora 24/7',
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        content: const Text(
                          'Hotline CSKH: 1900 6868\nEmail: hotro@avora.vn\nThời gian làm việc: 24/7 tất cả các ngày trong tuần.',
                          style: TextStyle(fontSize: 13.5, height: 1.5),
                        ),
                        actions: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF003580),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: const Text('Hotline: 1900 6868'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
