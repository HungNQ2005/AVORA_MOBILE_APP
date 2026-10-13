import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/hotel_detail_model.dart';
import '../../data/models/room_capacity_helper.dart';

/// Hộp thoại xác nhận đặt phòng thành công
/// Tái hiện 100% modal "Đặt chỗ thành công!" từ bản Web.
class HotelDetailBookingModal extends StatelessWidget {
  final HotelDetailModel hotel;
  final RoomTypeDetailModel room;
  final String guestName;
  final String formattedStayDates;
  final int nights;
  final int adults;
  final int children;
  final int rooms;
  final VoidCallback onComplete;

  const HotelDetailBookingModal({
    super.key,
    required this.hotel,
    required this.room,
    required this.guestName,
    required this.formattedStayDates,
    required this.nights,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final capDetails = RoomCapacityHelper.getRoomCapacityDetails(
      bedType: room.bedType,
      maxAdults: room.maxAdults,
      maxChildren: room.maxChildren,
    );
    final totalPrice = room.price * nights;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon chúc mừng
              const Center(
                child: Text(
                  '🎉',
                  style: TextStyle(fontSize: 44),
                ),
              ),
              const SizedBox(height: 10),

              // Tiêu đề
              const Text(
                'Đặt chỗ thành công!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF003580),
                ),
              ),
              const SizedBox(height: 8),

              // Mô tả
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF4B5563)),
                  children: [
                    const TextSpan(text: 'Bạn đã chọn '),
                    TextSpan(
                      text: room.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const TextSpan(text: ' tại '),
                    TextSpan(
                      text: hotel.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003580),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Bảng tóm tắt thông tin đặt phòng
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRow('Khách đặt phòng:', guestName, isBold: true),
                    const Divider(height: 14),
                    _buildRow(
                      'Thời gian lưu trú:',
                      '$formattedStayDates ($nights đêm)',
                    ),
                    const Divider(height: 14),
                    _buildRow(
                      'Số lượng khách:',
                      '$adults người lớn${children > 0 ? ', $children trẻ em' : ''} ($rooms phòng)',
                    ),
                    const Divider(height: 14),
                    _buildRow(
                      'Cấu hình sức chứa:',
                      '${capDetails.standardBeds} giường tiêu chuẩn (${capDetails.standardCapacity} người)${capDetails.hasExtraBed ? ' + 1 giường phụ' : ''} = Tối đa ${capDetails.maxCapacity} người',
                    ),
                    const Divider(height: 14),
                    _buildRow(
                      'Trạng thái sức chứa:',
                      '✓ Hợp lệ (≤ ${capDetails.maxCapacity} người/phòng)',
                      valueColor: const Color(0xFF008009),
                      isBold: true,
                    ),
                    const Divider(height: 14),
                    _buildRow(
                      'Chính sách hủy:',
                      'Miễn phí hủy phòng',
                      valueColor: const Color(0xFF008009),
                    ),
                    const Divider(height: 14),
                    _buildRow(
                      'Tổng giá tạm tính:',
                      '${currencyFormatter.format(totalPrice)} VND',
                      valueColor: const Color(0xFF003580),
                      isBold: true,
                      valueSize: 15,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nút hoàn tất & đóng
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006CE4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: onComplete,
                child: const Text(
                  'Hoàn tất & Đóng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    double valueSize = 13,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
