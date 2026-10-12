import 'package:flutter/material.dart';
import 'home_helpers.dart';

/// Banner giới thiệu bản đồ du lịch tương tác.
class InteractiveMapBanner extends StatelessWidget {
  const InteractiveMapBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.explore, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Text(
                      'Bản đồ du lịch tương tác',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tìm khách sạn trên bản đồ địa phương',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Định vị các khách sạn ven biển, gần trung tâm du lịch theo ngân sách.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF003580),
                    side: const BorderSide(color: Color(0xFF003580)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Mở xem bản đồ'),
                  onPressed: () =>
                      showHomeSnackBar(context, 'Tính năng Bản đồ đang mở...'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=300&q=80',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: const Color(0xFFE2E8F0),
                child: const Icon(Icons.map, color: Color(0xFF0284C7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
