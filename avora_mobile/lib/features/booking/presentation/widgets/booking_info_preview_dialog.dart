import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/guest_booking_info.dart';

/// Hộp thoại/BottomSheet xem lại thông tin khách lưu trú vừa nhập
/// Giúp người dùng kiểm tra độ chính xác của Họ tên, SĐT và Yêu cầu đặc biệt
class BookingInfoPreviewDialog extends StatelessWidget {
  final GuestBookingInfo info;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const BookingInfoPreviewDialog({
    super.key,
    required this.info,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AvoraTheme.primaryNavy.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.badge_rounded,
                    color: AvoraTheme.primaryNavy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác nhận thông tin khách',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Vui lòng kiểm tra lại trước khi chuyển sang bước tiếp theo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AvoraTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AvoraTheme.cardBorder),
            const SizedBox(height: 16),

            // Thông tin họ tên
            _buildInfoRow(
              icon: Icons.person_outline_rounded,
              title: 'Họ và tên người nhận phòng',
              value: info.fullName,
              isHighlight: true,
            ),
            const SizedBox(height: 12),

            // Số điện thoại
            _buildInfoRow(
              icon: Icons.phone_outlined,
              title: 'Số điện thoại liên hệ',
              value: '${info.countryCode} ${info.phone}',
              isHighlight: true,
            ),
            const SizedBox(height: 12),

            // Yêu cầu đặc biệt
            _buildInfoRow(
              icon: Icons.tune_rounded,
              title: 'Yêu cầu đặc biệt',
              value: info.selectedRequests.isEmpty
                  ? 'Không có yêu cầu tiêu chuẩn'
                  : info.selectedRequests.join(', '),
            ),

            if (info.customNote.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.edit_note_rounded,
                title: 'Ghi chú thêm',
                value: info.customNote.trim(),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AvoraTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Chỉnh sửa lại',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AvoraTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AvoraTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xác nhận thông tin',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AvoraTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AvoraTheme.primaryNavy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AvoraTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                    color: isHighlight
                        ? AvoraTheme.textPrimary
                        : AvoraTheme.textBody,
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
