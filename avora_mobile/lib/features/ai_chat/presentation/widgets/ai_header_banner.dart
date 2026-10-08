import 'package:flutter/material.dart';

/// Banner tiêu đề + các câu gợi ý nhanh của trang Trợ lý AI.
class AiHeaderBanner extends StatelessWidget {
  final ValueChanged<String> onPrompt;
  final bool enabled;

  const AiHeaderBanner({super.key, required this.onPrompt, this.enabled = true});

  static const _prompts = [
    ('💰', 'Ngân sách tối đa 2 triệu/đêm'),
    ('👨‍👩‍👦', 'Cho 2 người lớn + 1 trẻ nhỏ'),
    ('🏖', 'Gần biển Mỹ Khê Đà Nẵng'),
    ('🍳', 'Có buffet sáng & hồ bơi'),
    ('🌿', 'Nghỉ dưỡng yên tĩnh, thiết kế'),
    ('💼', 'Công tác trung tâm thành phố'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003580), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 13),
                SizedBox(width: 6),
                Text(
                  'THUẬT TOÁN KHỚP PHÒNG CÁ NHÂN HÓA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Flexible(
                child: Text(
                  'Trợ lý Du lịch AI Avora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 20),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Chia sẻ ngân sách, phong cách chuyến đi và mong muốn của bạn — '
            'AI sẽ phân tích dữ liệu chỗ nghỉ Avora và gợi ý hạng phòng phù hợp nhất.',
            style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _prompts.map((p) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: enabled ? () => onPrompt(p.$2) : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.$1, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        p.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
