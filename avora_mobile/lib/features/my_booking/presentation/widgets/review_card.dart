import 'package:flutter/material.dart';

import '../../data/models/booking_review_model.dart';

class ReviewCard extends StatelessWidget {
  final BookingReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 5),
              Text(
                '${review.ratingScore}/10',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (review.createdAt != null) ...[
                const Spacer(),
                Text(
                  _formatDate(review.createdAt!),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              review.comment,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ] else ...[
            const SizedBox(height: 9),
            const Text(
              'Không có nhận xét.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    } catch (_) {
      return value;
    }
  }
}
