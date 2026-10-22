import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/coupon_model.dart';
import '../../data/repositories/booking_repository.dart';

class BookingCouponState extends Equatable {
  final bool isLoading;
  final bool isApplying;
  final BookingPricingModel? pricing;
  final String? couponMessage;
  final bool? isSuccess;
  final String? errorMessage;

  const BookingCouponState({
    this.isLoading = false,
    this.isApplying = false,
    this.pricing,
    this.couponMessage,
    this.isSuccess,
    this.errorMessage,
  });

  CouponModel? get appliedCoupon => pricing?.coupon;
  num get subtotal => pricing?.subtotal ?? 0;
  num get discountAmount => pricing?.discountAmount ?? 0;
  num get totalAmount => pricing?.totalAmount ?? subtotal;
  List<CouponModel> get availableCoupons => pricing?.availableCoupons ?? [];

  BookingCouponState copyWith({
    bool? isLoading,
    bool? isApplying,
    BookingPricingModel? pricing,
    String? couponMessage,
    bool? isSuccess,
    String? errorMessage,
    bool clearMessage = false,
  }) {
    return BookingCouponState(
      isLoading: isLoading ?? this.isLoading,
      isApplying: isApplying ?? this.isApplying,
      pricing: pricing ?? this.pricing,
      couponMessage: clearMessage ? null : (couponMessage ?? this.couponMessage),
      isSuccess: clearMessage ? null : (isSuccess ?? this.isSuccess),
      errorMessage: clearMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isApplying,
        pricing,
        couponMessage,
        isSuccess,
        errorMessage,
      ];
}

class BookingCouponNotifier extends StateNotifier<BookingCouponState> {
  final BookingRepository _repository;
  String _hotelId = '';
  String _roomTypeId = '';
  int _quantity = 1;
  String _checkInDate = '';
  String _checkOutDate = '';

  BookingCouponNotifier(this._repository) : super(const BookingCouponState());

  /// Khởi tạo và tải thông tin bảng giá cùng danh sách Voucher sẵn có từ backend.
  Future<void> init({
    required String hotelId,
    required String roomTypeId,
    required int quantity,
    required String checkInDate,
    required String checkOutDate,
    num? fallbackSubtotal,
  }) async {
    _hotelId = hotelId;
    _roomTypeId = roomTypeId;
    _quantity = quantity;
    _checkInDate = checkInDate;
    _checkOutDate = checkOutDate;

    // Nếu thiếu thông tin để gọi API tính toán (ví dụ fallback mock), thiết lập fallback state
    if (_hotelId.isEmpty || _roomTypeId.isEmpty) {
      final baseSubtotal = fallbackSubtotal ?? 1800000;
      state = state.copyWith(
        pricing: BookingPricingModel(
          subtotal: baseSubtotal,
          totalAmount: baseSubtotal,
          availableCoupons: const [
            CouponModel(
              couponId: 'c1',
              code: 'SAIGON10',
              discountType: 'PERCENT',
              discountValue: 10,
              minOrderAmount: 1200000,
            ),
            CouponModel(
              couponId: 'c2',
              code: 'AVORA15',
              discountType: 'PERCENT',
              discountValue: 15,
              minOrderAmount: 2000000,
            ),
          ],
        ),
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearMessage: true);

    try {
      final pricing = await _repository.calculatePricing(
        hotelId: _hotelId,
        roomTypeId: _roomTypeId,
        quantity: _quantity,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
      );

      state = state.copyWith(
        isLoading: false,
        pricing: pricing,
      );
    } catch (e) {
      // Fallback giữ nguyên giao dịch nếu backend gián đoạn
      final baseSubtotal = fallbackSubtotal ?? 1800000;
      state = state.copyWith(
        isLoading: false,
        pricing: BookingPricingModel(
          subtotal: baseSubtotal,
          totalAmount: baseSubtotal,
          availableCoupons: const [
            CouponModel(
              couponId: 'c1',
              code: 'SAIGON10',
              discountType: 'PERCENT',
              discountValue: 10,
              minOrderAmount: 1200000,
            ),
          ],
        ),
      );
    }
  }

  /// Áp dụng mã giảm giá
  Future<void> applyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      state = state.copyWith(
        couponMessage: 'Vui lòng nhập mã giảm giá.',
        isSuccess: false,
      );
      return;
    }

    state = state.copyWith(isApplying: true, clearMessage: true);

    try {
      // Nếu có đầy đủ thông tin khách sạn và phòng, gọi backend tính toán chính xác
      if (_hotelId.isNotEmpty && _roomTypeId.isNotEmpty) {
        final pricing = await _repository.calculatePricing(
          hotelId: _hotelId,
          roomTypeId: _roomTypeId,
          quantity: _quantity,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          couponCode: cleanCode,
        );

        final isSuccess = pricing.discountAmount > 0 && pricing.coupon != null;
        state = state.copyWith(
          isApplying: false,
          pricing: pricing,
          couponMessage: pricing.couponMessage ??
              (isSuccess
                  ? 'Đã áp dụng mã $cleanCode thành công!'
                  : 'Mã giảm giá "$cleanCode" không hợp lệ.'),
          isSuccess: isSuccess,
        );
      } else {
        // Fallback offline simulation
        final currentSub = state.subtotal;
        if (cleanCode.contains('10') || cleanCode == 'SAIGON10') {
          final discount = (currentSub * 0.1).round();
          state = state.copyWith(
            isApplying: false,
            pricing: BookingPricingModel(
              subtotal: currentSub,
              discountAmount: discount,
              totalAmount: currentSub - discount,
              coupon: CouponModel(
                couponId: 'c1',
                code: cleanCode,
                discountType: 'PERCENT',
                discountValue: 10,
              ),
              couponMessage: 'Đã áp dụng mã $cleanCode (-$discount ₫)',
              availableCoupons: state.availableCoupons,
            ),
            couponMessage: 'Đã áp dụng mã $cleanCode thành công!',
            isSuccess: true,
          );
        } else {
          state = state.copyWith(
            isApplying: false,
            couponMessage: 'Mã giảm giá "$cleanCode" không tồn tại trong hệ thống.',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isApplying: false,
        couponMessage: e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    }
  }

  /// Bỏ mã giảm giá hiện tại
  Future<void> removeCoupon() async {
    state = state.copyWith(isApplying: true, clearMessage: true);

    try {
      if (_hotelId.isNotEmpty && _roomTypeId.isNotEmpty) {
        final pricing = await _repository.calculatePricing(
          hotelId: _hotelId,
          roomTypeId: _roomTypeId,
          quantity: _quantity,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
        );

        state = state.copyWith(
          isApplying: false,
          pricing: pricing,
          couponMessage: 'Đã hủy áp dụng mã giảm giá.',
          isSuccess: true,
        );
      } else {
        final sub = state.subtotal;
        state = state.copyWith(
          isApplying: false,
          pricing: BookingPricingModel(
            subtotal: sub,
            totalAmount: sub,
            availableCoupons: state.availableCoupons,
          ),
          couponMessage: 'Đã hủy áp dụng mã giảm giá.',
          isSuccess: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isApplying: false,
        errorMessage: 'Không thể cập nhật lại giá tiền.',
      );
    }
  }
}

final bookingCouponProvider =
    StateNotifierProvider.autoDispose<BookingCouponNotifier, BookingCouponState>(
        (ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return BookingCouponNotifier(repo);
});
