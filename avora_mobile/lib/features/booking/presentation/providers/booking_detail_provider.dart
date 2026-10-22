import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/booking_detail_model.dart';
import '../../data/repositories/booking_repository.dart';

/// Provider lấy dữ liệu chi tiết của một đơn đặt phòng dựa trên bookingId
final bookingDetailProvider =
    FutureProvider.autoDispose.family<BookingDetailModel, String>((ref, bookingId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingDetail(bookingId);
});

/// Provider lấy danh sách đặt phòng của người dùng theo trạng thái
final myBookingsListProvider =
    FutureProvider.autoDispose.family<List<BookingDetailModel>, String>((ref, status) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getMyBookings(status: status);
});

/// Provider lấy tất cả các đơn đặt phòng của người dùng
final myAllBookingsProvider =
    FutureProvider.autoDispose<List<BookingDetailModel>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getMyBookings(status: 'all');
});

