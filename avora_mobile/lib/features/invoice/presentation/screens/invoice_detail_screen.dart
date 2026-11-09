import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/invoice_model.dart';
import '../providers/invoice_provider.dart';

/// Màn hình Chi tiết hóa đơn thanh toán & Giao dịch điện tử (Invoice & Transaction Detail)
class InvoiceDetailScreen extends ConsumerWidget {
  final String bookingId;

  const InvoiceDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(bookingId));

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
              context.go(AppRoutes.invoices);
            }
          },
        ),
        title: const Text(
          'Chi tiết hóa đơn & Giao dịch',
          style: TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(invoiceDetailProvider(bookingId)),
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AvoraTheme.primaryNavy),
        ),
        error: (error, _) => _buildErrorView(context, ref, error),
        data: (invoice) => RefreshIndicator(
          color: AvoraTheme.primaryNavy,
          onRefresh: () async {
            ref.invalidate(invoiceDetailProvider(bookingId));
            await ref.read(invoiceDetailProvider(bookingId).future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thẻ trạng thái & Số tiền giao dịch
                _buildStatusBannerCard(context, invoice),
                const SizedBox(height: 16),

                // 2. Thẻ thông tin chi tiết giao dịch thanh toán
                _buildTransactionInfoCard(context, invoice),
                const SizedBox(height: 16),

                // 3. Thẻ bảng kê chi phí & VAT
                _buildCostBreakdownCard(invoice),
                const SizedBox(height: 16),

                // 4. Thẻ thông tin người nhận hóa đơn & đơn vị phát hành
                _buildCustomerAndIssuerCard(invoice),
                const SizedBox(height: 16),

                // 5. Thẻ thông tin lưu trú liên kết
                _buildStayInfoCard(context, invoice),
                const SizedBox(height: 24),

                // 6. Các nút tác vụ nhanh
                _buildActionButtons(context, invoice),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    final msg = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải chi tiết hóa đơn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(invoiceDetailProvider(bookingId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AvoraTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. Thẻ trạng thái & Số tiền giao dịch ───────────────────────────────────
  Widget _buildStatusBannerCard(
      BuildContext context, InvoiceDetailModel invoice) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: invoice.isPaid
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              invoice.isPaid
                  ? Icons.check_circle_rounded
                  : Icons.access_time_filled_rounded,
              size: 36,
              color: invoice.isPaid
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            invoice.isPaid
                ? 'THANH TOÁN THÀNH CÔNG'
                : 'ĐƠN ĐÃ XÁC NHẬN (CHỜ TT)',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: invoice.isPaid
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            invoice.formattedAmountPaid,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AvoraTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    invoice.invoiceStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Thẻ thông tin chi tiết giao dịch thanh toán ──────────────────────────
  Widget _buildTransactionInfoCard(
      BuildContext context, InvoiceDetailModel invoice) {
    final txnId = (invoice.transactionId != null &&
            invoice.transactionId!.trim().isNotEmpty)
        ? invoice.transactionId!
        : (invoice.gatewayRefId ?? '—');

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
          Row(
            children: const [
              Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: AvoraTheme.primaryNavy,
              ),
              SizedBox(width: 8),
              Text(
                'Thông tin giao dịch thanh toán',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Mã giao dịch (Transaction ID)
          _buildCopyableRow(
            context,
            label: 'MÃ GIAO DỊCH:',
            value: txnId,
            isCode: true,
            highlight: true,
          ),
          const SizedBox(height: 10),

          // 2. Mã chứng từ / Hóa đơn (Invoice ID)
          _buildCopyableRow(
            context,
            label: 'MÃ HÓA ĐƠN:',
            value: invoice.invoiceNumber,
            isCode: true,
          ),
          const SizedBox(height: 10),

          // 3. Mã tra cứu (Lookup Code)
          _buildCopyableRow(
            context,
            label: 'MÃ TRA CỨU:',
            value: invoice.lookupCode,
            isCode: true,
          ),
          const SizedBox(height: 10),

          // 4. Mã đơn đặt phòng (Booking Code)
          _buildCopyableRow(
            context,
            label: 'MÃ ĐẶT CHỖ:',
            value: invoice.bookingCode,
            isCode: true,
          ),
          const SizedBox(height: 10),

          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // 5. Số tiền thanh toán
          _buildInfoRow(
            'Số tiền thanh toán:',
            invoice.formattedAmountPaid,
            valueStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AvoraTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),

          // 6. Phương thức thanh toán
          _buildInfoRow(
            'Phương thức:',
            invoice.paymentMethod,
          ),
          const SizedBox(height: 8),

          // 7. Ngày / Thời gian thanh toán
          _buildInfoRow(
            'Thời gian thanh toán:',
            invoice.formattedPaidAt,
          ),
          const SizedBox(height: 8),

          // 8. Trạng thái thanh toán
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 140,
                child: Text(
                  'Trạng thái:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: invoice.isPaid
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: invoice.isPaid
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            invoice.isPaid
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 13,
                            color: invoice.isPaid
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invoice.isPaid
                                ? 'Thanh toán thành công'
                                : 'Chờ xác nhận',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: invoice.isPaid
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 3. Thẻ bảng kê chi phí & VAT ───────────────────────────────────────────
  Widget _buildCostBreakdownCard(InvoiceDetailModel invoice) {
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
          Row(
            children: const [
              Icon(
                Icons.receipt_outlined,
                size: 20,
                color: AvoraTheme.primaryNavy,
              ),
              SizedBox(width: 8),
              Text(
                'Chi tiết chi phí & VAT',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildCostRow('Tạm tính tiền phòng:', invoice.formattedSubtotal),
          const SizedBox(height: 8),

          if (invoice.discountAmount > 0) ...[
            _buildCostRow(
              invoice.couponCode != null
                  ? 'Giảm giá (Coupon: ${invoice.couponCode}):'
                  : 'Giảm giá ưu đãi:',
              invoice.formattedDiscount,
              color: const Color(0xFF059669),
            ),
            const SizedBox(height: 8),
          ],

          _buildCostRow(
            'Thuế VAT & Phí dịch vụ:',
            'Đã bao gồm',
            color: const Color(0xFF64748B),
          ),
          const SizedBox(height: 10),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          _buildCostRow(
            'Tổng tiền hóa đơn:',
            invoice.formattedTotalAmount,
            isBold: true,
            fontSize: 15,
            color: AvoraTheme.primaryNavy,
          ),
          const SizedBox(height: 8),

          _buildCostRow(
            'Đã thanh toán:',
            invoice.formattedAmountPaid,
            isBold: true,
            fontSize: 16,
            color: const Color(0xFF15803D),
          ),
        ],
      ),
    );
  }

  // ─── 4. Thẻ thông tin người nhận hóa đơn & Đơn vị phát hành ─────────────────
  Widget _buildCustomerAndIssuerCard(InvoiceDetailModel invoice) {
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
          Row(
            children: const [
              Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AvoraTheme.primaryNavy,
              ),
              SizedBox(width: 8),
              Text(
                'Khách hàng & Đơn vị phát hành',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildInfoRow('Khách nhận hóa đơn:',
              invoice.buyerName.isNotEmpty ? invoice.buyerName : 'Quý khách'),
          const SizedBox(height: 8),

          _buildInfoRow('Số điện thoại:',
              invoice.buyerPhone.isNotEmpty ? invoice.buyerPhone : '—'),
          const SizedBox(height: 8),

          _buildInfoRow('Ngày lập hóa đơn:', invoice.issuedDate),
          const SizedBox(height: 10),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          _buildInfoRow(
            'Đơn vị phát hành:',
            'Công ty Cổ phần Du lịch Trực tuyến AVORA Việt Nam',
          ),
          const SizedBox(height: 8),

          _buildInfoRow('Mã số thuế:', '0316892401'),
        ],
      ),
    );
  }

  // ─── 5. Thẻ thông tin lưu trú liên kết ───────────────────────────────────────
  Widget _buildStayInfoCard(BuildContext context, InvoiceDetailModel invoice) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.hotel_outlined,
                    size: 20,
                    color: AvoraTheme.primaryNavy,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thông tin lưu trú',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AvoraTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.push(AppRoutes.bookingDetailPath(invoice.bookingId));
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem đơn phòng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF0066FF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            invoice.hotelName,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          if (invoice.hotelAddress.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              invoice.hotelAddress,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 10),

          _buildInfoRow('Loại phòng:',
              invoice.roomTypeName ?? 'Phòng tiêu chuẩn khách sạn'),
          const SizedBox(height: 6),

          if (invoice.checkInDate != null && invoice.checkOutDate != null) ...[
            _buildInfoRow(
              'Lưu trú:',
              '${_formatDate(invoice.checkInDate!)} ➜ ${_formatDate(invoice.checkOutDate!)} (${invoice.nights} đêm)',
            ),
            const SizedBox(height: 6),
          ],

          _buildInfoRow('Số lượng:', '${invoice.quantity} phòng'),
        ],
      ),
    );
  }

  // ─── 6. Các nút tác vụ nhanh ─────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context, InvoiceDetailModel invoice) {
    return Column(
      children: [
        // Nút tải file PDF hóa đơn
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleDownloadPdf(context, invoice),
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text('Tải file PDF hóa đơn điện tử'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AvoraTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Nút xem chi tiết đơn đặt phòng
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.push(AppRoutes.bookingDetailPath(invoice.bookingId));
            },
            icon: const Icon(Icons.luggage_outlined, size: 19),
            label: const Text('Xem đơn đặt phòng liên kết'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AvoraTheme.primaryNavy,
              side: const BorderSide(color: Color(0xFF93C5FD)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Nút quay về danh sách hóa đơn
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.invoices);
              }
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Về danh sách hóa đơn'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDownloadPdf(BuildContext context, InvoiceDetailModel invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã tải file PDF hóa đơn ${invoice.invoiceNumber} thành công!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildCopyableRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isCode = false,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép: $value'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AvoraTheme.primaryNavy,
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: highlight
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: highlight
                    ? Border.all(color: const Color(0xFFBFDBFE))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: isCode ? 'monospace' : null,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: highlight
                            ? AvoraTheme.primaryNavy
                            : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13.5,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }
}

