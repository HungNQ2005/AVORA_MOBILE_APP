import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/guest_booking_info.dart';

/// Card 2: Yêu cầu đặc biệt cho chỗ nghỉ (Tùy chọn không mất phí)
/// Đồng bộ 1:1 với `SpecialRequestsCard.jsx` trên Website Avora.
class BookingSpecialRequestsCard extends StatelessWidget {
  final String hotelName;
  final List<String> selectedRequests;
  final ValueChanged<String> onToggleRequest;
  final TextEditingController noteController;
  final VoidCallback? onNoteChanged;

  const BookingSpecialRequestsCard({
    super.key,
    required this.hotelName,
    required this.selectedRequests,
    required this.onToggleRequest,
    required this.noteController,
    this.onNoteChanged,
  });

  IconData _getIconForRequest(String request) {
    if (request.contains('không hút thuốc')) return Icons.smoke_free_rounded;
    if (request.contains('giường lớn')) return Icons.king_bed_outlined;
    if (request.contains('sớm')) return Icons.alarm_outlined;
    if (request.contains('Cũi') || request.contains('trẻ')) return Icons.child_friendly_outlined;
    if (request.contains('biển') || request.contains('yên tĩnh')) return Icons.waves_rounded;
    return Icons.star_border_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Icon Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AvoraTheme.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AvoraTheme.primaryNavy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yêu cầu đặc biệt cho chỗ nghỉ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Các yêu cầu không mất phí và được $hotelName phục vụ linh hoạt tùy vào tình trạng phòng sẵn có lúc nhận phòng.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AvoraTheme.textMuted,
                          height: 1.35,
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

            // Danh sách lựa chọn tiêu chuẩn (Checkbox List)
            const Text(
              'Yêu cầu phổ biến:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AvoraTheme.textBody,
              ),
            ),
            const SizedBox(height: 8),

            ...GuestBookingInfo.standardRequests.map((item) {
              final isChecked = selectedRequests.contains(item);
              final icon = _getIconForRequest(item);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isChecked ? const Color(0xFFF0F7FF) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onToggleRequest(item),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isChecked
                              ? AvoraTheme.actionBlue
                              : AvoraTheme.cardBorder,
                          width: isChecked ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 19,
                            color: isChecked
                                ? AvoraTheme.actionBlue
                                : AvoraTheme.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isChecked
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isChecked
                                    ? AvoraTheme.primaryNavy
                                    : AvoraTheme.textPrimary,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isChecked,
                            onChanged: (_) => onToggleRequest(item),
                            activeColor: AvoraTheme.actionBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Ghi chú riêng textarea
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ghi chú riêng bằng Tiếng Việt hoặc Tiếng Anh (tùy chọn):',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AvoraTheme.textBody,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            ValueListenableBuilder<TextEditingValue>(
              valueListenable: noteController,
              builder: (context, value, _) {
                final currentLength = value.text.length;
                final isOverLimit =
                    currentLength > GuestBookingInfo.maxSpecialRequestLength;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: noteController,
                      maxLines: 4,
                      minLines: 3,
                      maxLength: GuestBookingInfo.maxSpecialRequestLength,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          null, // Custom counter bên dưới
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AvoraTheme.textPrimary,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Gia đình có người cao tuổi, cần hỗ trợ xe điện buggy ra biển khi nhận phòng...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AvoraTheme.inputBorder,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isOverLimit
                                ? AvoraTheme.errorRed
                                : AvoraTheme.inputBorder,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isOverLimit
                                ? AvoraTheme.errorRed
                                : AvoraTheme.primaryNavy,
                            width: 1.8,
                          ),
                        ),
                      ),
                      onChanged: (_) => onNoteChanged?.call(),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isOverLimit
                              ? 'Vượt quá giới hạn cho phép'
                              : 'Tối đa ${GuestBookingInfo.maxSpecialRequestLength} ký tự',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverLimit
                                ? AvoraTheme.errorRed
                                : AvoraTheme.textMuted,
                          ),
                        ),
                        Text(
                          '$currentLength / ${GuestBookingInfo.maxSpecialRequestLength}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOverLimit
                                ? AvoraTheme.errorRed
                                : AvoraTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
