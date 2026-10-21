import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/booking_detail_model.dart';
import '../providers/booking_detail_provider.dart';

/// Màn hình hiển thị chi tiết một đơn đặt phòng đã chọn (View Booking Details).
/// Đồng bộ 1:1 với Web FE & BE Avora OTA:
/// Hiển thị thông tin chỗ nghỉ, mã đặt phòng, trạng thái hiện tại, thời gian nhận & trả phòng,
/// thông tin khách, chi tiết chi phí và chính sách hủy.
class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: AvoraTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AvoraTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.myBooking);
            }
          },
        ),
        title: const Text(
          'Chi tiết đơn đặt phòng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(bookingDetailProvider(bookingId)),
          ),
        ],
      ),
      body: bookingAsync.when(
        loading: () => const _BookingDetailLoadingView(),
        error: (error, _) => _BookingDetailErrorView(
          errorMessage: error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
        ),
        data: (booking) => RefreshIndicator(
          color: AvoraTheme.primaryNavy,
          onRefresh: () async {
            ref.invalidate(bookingDetailProvider(bookingId));
            await ref.read(bookingDetailProvider(bookingId).future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thẻ mã đơn & trạng thái hiện tại (Status Card)
                _buildStatusBanner(context, booking),
                const SizedBox(height: 16),

                // 2. Thẻ thời gian Nhận phòng & Trả phòng (Check-in / Check-out Schedule)
                _buildStayScheduleCard(booking),
                const SizedBox(height: 16),

                // 3. Thẻ thông tin khách sạn & phòng nghỉ (Hotel & Room Information)
                _buildHotelAndRoomCard(booking),
                const SizedBox(height: 16),

                // 4. Thẻ thông tin khách lưu trú (Guest Information)
                _buildGuestInfoCard(booking),
                const SizedBox(height: 16),

                // 5. Thẻ chi tiết thanh toán & chi phí (Pricing & Payment Breakdown)
                _buildPaymentBreakdownCard(booking),
                const SizedBox(height: 16),

                // 6. Thẻ chính sách & Hướng dẫn nhận phòng (Cancellation & Notice)
                _buildPolicyNoticeCard(booking),
                const SizedBox(height: 24),

                // 7. Các nút tác vụ nhanh phía dưới (Bottom Actions)
                _buildBottomButtons(context, booking),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. Thẻ trạng thái & Mã đặt phòng ────────────────────────────────────
  Widget _buildStatusBanner(BuildContext context, BookingDetailModel booking) {
    final statusStyle = _getStatusVisuals(booking.statusBadgeVariant);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge trạng thái hiện tại
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusStyle.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusStyle.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusStyle.icon, size: 15, color: statusStyle.textColor),
                    const SizedBox(width: 5),
                    Text(
                      booking.statusName,
                      style: TextStyle(
                        color: statusStyle.textColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Nút sao chép mã đặt chỗ
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: booking.bookingCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép mã ${booking.bookingCode} vào bộ nhớ tạm'),
                      backgroundColor: AvoraTheme.primaryNavy,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${booking.bookingCode}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 14, color: AvoraTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (booking.formattedCreatedAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_note_outlined, size: 15, color: AvoraTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Thời gian đặt: ${booking.formattedCreatedAt}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AvoraTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── 2. Thẻ thời gian Nhận phòng & Trả phòng (Schedule Card) ──────────────
  Widget _buildStayScheduleCard(BookingDetailModel booking) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: AvoraTheme.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Lịch trình lưu trú',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Check-in Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NHẬN PHÒNG',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Từ 14:00',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AvoraTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.checkInDate.isNotEmpty ? booking.formattedCheckIn.replaceFirst('Từ 14:00, ', '') : '—',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AvoraTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Center Duration Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${booking.nights} đêm',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AvoraTheme.textMuted),
                  ],
                ),
              ),

              // Check-out Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRẢ PHÒNG',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Trước 12:00',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AvoraTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.checkOutDate.isNotEmpty ? booking.formattedCheckOut.replaceFirst('Trước 12:00, ', '') : '—',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AvoraTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 3. Thẻ thông tin khách sạn & Phòng nghỉ ──────────────────────────────
  Widget _buildHotelAndRoomCard(BookingDetailModel booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header khách sạn
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail khách sạn
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFE2E8F0),
                    child: booking.hotelThumbnailUrl != null && booking.hotelThumbnailUrl!.isNotEmpty
                        ? Image.network(
                            booking.hotelThumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.hotel_rounded,
                              size: 32,
                              color: AvoraTheme.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.hotel_rounded,
                            size: 32,
                            color: AvoraTheme.textMuted,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Tên & địa chỉ khách sạn
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (booking.hotelStarQuality != null && booking.hotelStarQuality! > 0)
                        Row(
                          children: List.generate(
                            booking.hotelStarQuality!,
                            (_) => const Icon(Icons.star_rounded, size: 14, color: AvoraTheme.accentGold),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        booking.hotelName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AvoraTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AvoraTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.hotelAddress.isNotEmpty ? booking.hotelAddress : 'Đang cập nhật địa chỉ',
                              style: const TextStyle(fontSize: 12, color: AvoraTheme.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AvoraTheme.cardBorder),

          // Chi tiết phòng nghỉ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 18, color: AvoraTheme.primaryNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.roomTypeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AvoraTheme.primaryNavy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${booking.quantity} phòng',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Specs: Giường, Diện tích, Sức chứa
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (booking.bedType != null && booking.bedType!.isNotEmpty)
                      _buildSpecPill(Icons.single_bed_outlined, booking.bedType!),
                    if (booking.roomSize != null && booking.roomSize!.isNotEmpty)
                      _buildSpecPill(Icons.square_foot_outlined, booking.roomSize!),
                    _buildSpecPill(Icons.people_outline_rounded, booking.guestsSummary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AvoraTheme.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AvoraTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Thẻ thông tin khách lưu trú ──────────────────────────────────────
  Widget _buildGuestInfoCard(BookingDetailModel booking) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: AvoraTheme.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Thông tin khách đại diện',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildInfoRow('Họ và tên:', booking.guestName.isNotEmpty ? booking.guestName : '—'),
          const SizedBox(height: 8),
          _buildInfoRow('Số điện thoại:', booking.guestPhone.isNotEmpty ? booking.guestPhone : '—'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Yêu cầu đặc biệt:',
            (booking.specialRequest != null && booking.specialRequest!.trim().isNotEmpty)
                ? booking.specialRequest!
                : 'Không có yêu cầu đặc biệt',
          ),
        ],
      ),
    );
  }

  // ─── 5. Thẻ chi tiết thanh toán & Chi phí ─────────────────────────────────
  Widget _buildPaymentBreakdownCard(BookingDetailModel booking) {
    final currency = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: AvoraTheme.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Chi tiết giá & Thanh toán',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Giá niêm yết theo số đêm & phòng
          if (booking.unitPrice > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Tiền phòng (${booking.quantity} phòng × ${booking.nights} đêm):',
                    style: const TextStyle(fontSize: 13, color: AvoraTheme.textSecondary),
                  ),
                ),
                Text(
                  '${currency.format(booking.unitPrice * booking.quantity * booking.nights)} ₫',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AvoraTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Giảm giá (nếu có áp dụng voucher)
          if (booking.discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Khuyến mãi đã áp dụng:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF059669)),
                    ),
                    if (booking.couponCode != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          booking.couponCode!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '-${currency.format(booking.discountAmount)} ₫',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 18, color: AvoraTheme.cardBorder),

          // Tổng tiền thanh toán
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán:',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
              Text(
                '${currency.format(booking.totalAmount)} ₫',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Phương thức & trạng thái thanh toán
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: booking.isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: booking.isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  booking.isPaid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: booking.isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.isPaid
                        ? 'Đã thanh toán qua ${booking.paymentMethod ?? 'chuyển khoản'}'
                        : 'Chưa thanh toán (${booking.paymentMethod ?? 'Thanh toán khi nhận phòng'})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: booking.isPaid ? const Color(0xFF047857) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. Thẻ chính sách & Hướng dẫn nhận phòng ─────────────────────────────
  Widget _buildPolicyNoticeCard(BookingDetailModel booking) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AvoraTheme.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Chính sách & Hướng dẫn',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (booking.cancellationPolicyDescription != null &&
              booking.cancellationPolicyDescription!.isNotEmpty) ...[
            Text(
              booking.cancellationPolicyDescription!,
              style: const TextStyle(fontSize: 12.5, color: AvoraTheme.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 10),
          ] else if (booking.freeCancelHours != null) ...[
            Text(
              'Hủy miễn phí trước ${booking.freeCancelHours} giờ so với thời điểm nhận phòng.',
              style: const TextStyle(fontSize: 12.5, color: AvoraTheme.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 10),
          ],

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: AvoraTheme.textMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Vui lòng xuất trình mã đặt phòng hoặc số điện thoại tại quầy lễ tân để hoàn tất thủ tục nhận phòng.',
                  style: TextStyle(fontSize: 12, color: AvoraTheme.textMuted, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 7. Các nút tác vụ ───────────────────────────────────────────────────
  Widget _buildBottomButtons(BuildContext context, BookingDetailModel booking) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.myBooking);
              }
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Về danh sách đặt chỗ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AvoraTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Về trang chủ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AvoraTheme.textSecondary,
              side: const BorderSide(color: AvoraTheme.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AvoraTheme.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AvoraTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  static ({Color bgColor, Color textColor, Color borderColor, IconData icon}) _getStatusVisuals(String variant) {
    return switch (variant) {
      'cancelled' => (
          bgColor: const Color(0xFFFEF2F2),
          textColor: const Color(0xFFDC2626),
          borderColor: const Color(0xFFFECACA),
          icon: Icons.cancel_rounded,
        ),
      'pending' => (
          bgColor: const Color(0xFFFFFBEB),
          textColor: const Color(0xFFD97706),
          borderColor: const Color(0xFFFDE68A),
          icon: Icons.schedule_rounded,
        ),
      'completed' => (
          bgColor: const Color(0xFFEFF6FF),
          textColor: const Color(0xFF2563EB),
          borderColor: const Color(0xFFBFDBFE),
          icon: Icons.task_alt_rounded,
        ),
      _ => (
          bgColor: const Color(0xFFECFDF5),
          textColor: const Color(0xFF059669),
          borderColor: const Color(0xFFA7F3D0),
          icon: Icons.check_circle_rounded,
        ),
    };
  }
}

// ─── Loading View ───────────────────────────────────────────────────────────
class _BookingDetailLoadingView extends StatelessWidget {
  const _BookingDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AvoraTheme.primaryNavy),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải thông tin đơn đặt phòng...',
            style: TextStyle(
              fontSize: 14,
              color: AvoraTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ─────────────────────────────────────────────────────────────
class _BookingDetailErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _BookingDetailErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AvoraTheme.errorRed,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không thể tải chi tiết đặt phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AvoraTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage.isNotEmpty ? errorMessage : 'Đã có lỗi xảy ra trong quá trình truy xuất dữ liệu từ máy chủ.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AvoraTheme.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AvoraTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
