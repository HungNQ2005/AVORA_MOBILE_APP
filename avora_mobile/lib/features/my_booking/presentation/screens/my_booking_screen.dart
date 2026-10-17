import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';

class MyBookingScreen extends StatelessWidget {
  const MyBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003580),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Quay lại',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          title: const Text(
            'Đặt chỗ của tôi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFBFDBFE),
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: 'Sắp tới'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingUnavailablePanel(
              title: 'Bạn chưa có lịch đặt nào',
              description:
                  'Hãy tìm một chỗ dừng chân cho chuyến đi sắp tới của bạn và đặt phòng ngay hôm nay.',
            ),
            _BookingUnavailablePanel(
              title: 'Chưa có lịch sử đặt chỗ',
              description:
                  'Những điểm dừng chân của bạn sẽ xuất hiện trong tương lai chúng ta đồng hành cùng nhau.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingUnavailablePanel extends StatelessWidget {
  final String title;
  final String description;

  const _BookingUnavailablePanel({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.luggage_outlined,
                color: Color(0xFF0284C7),
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dữ liệu đặt chỗ chưa được kết nối. Thông tin sẽ xuất hiện ở đây khi dịch vụ sẵn sàng.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.hotelSearch),
                icon: const Icon(Icons.search),
                label: const Text('Khám phá khách sạn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003580),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
