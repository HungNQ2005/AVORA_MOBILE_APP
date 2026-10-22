import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/booking_guest_info_args.dart';
import '../../data/models/guest_booking_info.dart';
import '../../data/repositories/booking_repository.dart';
import '../providers/booking_coupon_provider.dart';
import '../widgets/booking_contact_info_card.dart';
import '../widgets/booking_coupon_card.dart';
import '../widgets/booking_info_preview_dialog.dart';
import '../widgets/booking_special_requests_card.dart';
import '../widgets/booking_stay_summary_card.dart';
import '../widgets/booking_success_dialog.dart';

/// Màn hình Nhập thông tin chi tiết của khách lưu trú (Họ tên, SĐT, Yêu cầu đặc biệt).
/// Đồng bộ 100% với Usecase Đặt phòng và Schema validation của backend website Avora.
class BookingGuestInfoScreen extends ConsumerStatefulWidget {
  final BookingGuestInfoArgs? args;

  const BookingGuestInfoScreen({
    super.key,
    this.args,
  });

  @override
  ConsumerState<BookingGuestInfoScreen> createState() =>
      _BookingGuestInfoScreenState();
}

class _BookingGuestInfoScreenState extends ConsumerState<BookingGuestInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _noteController;
  late final TextEditingController _couponController;

  String _selectedCountryCode = '+84';
  final Set<String> _selectedRequests = {};

  String? _lastNameError;
  String? _firstNameError;
  String? _phoneError;
  bool _hasAttemptedSubmit = false;
  bool _isSubmitting = false;

  late final BookingGuestInfoArgs _args;

  @override
  void initState() {
    super.initState();
    _args = widget.args ?? const BookingGuestInfoArgs();

    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _phoneController = TextEditingController();
    _noteController = TextEditingController();
    _couponController = TextEditingController();

    // Tự động điền dữ liệu người dùng đăng nhập hiện tại nếu có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
      ref.read(bookingCouponProvider.notifier).init(
        hotelId: _args.hotel?.hotelId ?? '',
        roomTypeId: _args.room?.roomTypeId ?? '',
        quantity: _args.rooms,
        checkInDate: _args.checkInDate,
        checkOutDate: _args.checkOutDate,
        fallbackSubtotal: _args.totalPrice,
      );
    });
  }

  void _prefillUserData() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthSuccess) {
      final user = authState.user;
      final rawName = user.fullName ?? '';
      if (rawName.trim().isNotEmpty) {
        final parts = rawName.trim().split(RegExp(r'\s+'));
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(0, parts.length - 1).join(' ');
          _firstNameController.text = parts.last;
        } else {
          _firstNameController.text = parts.first;
        }
      }

      if (user.phone != null && user.phone!.isNotEmpty) {
        var cleanPhone = user.phone!.trim();
        if (cleanPhone.startsWith('+84')) {
          _selectedCountryCode = '+84';
          cleanPhone = cleanPhone.substring(3);
          if (!cleanPhone.startsWith('0')) cleanPhone = '0$cleanPhone';
        }
        _phoneController.text = cleanPhone;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _couponController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleRequest(String item) {
    setState(() {
      if (_selectedRequests.contains(item)) {
        _selectedRequests.remove(item);
      } else {
        if (_selectedRequests.length < GuestBookingInfo.maxSpecialRequestOptions) {
          _selectedRequests.add(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tối đa ${GuestBookingInfo.maxSpecialRequestOptions} yêu cầu đặc biệt.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  bool _validateInputs() {
    bool valid = true;
    final last = _lastNameController.text.trim();
    final first = _firstNameController.text.trim();
    final phone = _phoneController.text.trim();

    // 1. Kiểm tra Họ đệm
    if (last.isEmpty) {
      _lastNameError = 'Vui lòng nhập Họ và tên đệm.';
      valid = false;
    } else if (last.length < 2) {
      _lastNameError = 'Họ và tên đệm tối thiểu 2 ký tự.';
      valid = false;
    } else {
      _lastNameError = null;
    }

    // 2. Kiểm tra Tên
    if (first.isEmpty) {
      _firstNameError = 'Vui lòng nhập Tên của bạn.';
      valid = false;
    } else if (first.length < 2) {
      _firstNameError = 'Tên phải có tối thiểu 2 ký tự.';
      valid = false;
    } else {
      _firstNameError = null;
    }

    // 3. Kiểm tra tính hợp lệ toàn diện của tên
    if (valid) {
      final combinedName = '$last $first'.trim();
      if (!GuestBookingInfo.isValidGuestName(combinedName)) {
        _firstNameError = 'Họ tên chỉ được chứa chữ cái và dấu gạch nối.';
        valid = false;
      }
    }

    // 4. Kiểm tra Số điện thoại
    if (phone.isEmpty) {
      _phoneError = 'Vui lòng nhập số điện thoại liên hệ.';
      valid = false;
    } else if (!GuestBookingInfo.isValidGuestPhone(phone, _selectedCountryCode)) {
      _phoneError = _selectedCountryCode == '+84'
          ? 'Số điện thoại Việt Nam không hợp lệ (cần 10 số, bắt đầu 03, 05, 07, 08, 09).'
          : 'Số điện thoại quốc tế không đúng định dạng.';
      valid = false;
    } else {
      _phoneError = null;
    }

    setState(() {});
    return valid;
  }

  void _handleFieldChanged() {
    if (_hasAttemptedSubmit) {
      _validateInputs();
    }
  }

  void _handleSubmit() {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    final isValid = _validateInputs();
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin khách lưu trú.'),
          backgroundColor: AvoraTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _scrollController.animateTo(
        200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    final couponState = ref.read(bookingCouponProvider);
    final guestInfo = GuestBookingInfo(
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      countryCode: _selectedCountryCode,
      phone: _phoneController.text.trim(),
      selectedRequests: _selectedRequests.toList(),
      customNote: _noteController.text.trim(),
      couponCode: couponState.appliedCoupon?.code,
      discountAmount: couponState.discountAmount,
    );

    // Mở BottomSheet xem trước thông tin chuẩn bị xác nhận
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => BookingInfoPreviewDialog(
        info: guestInfo,
        onEdit: () => Navigator.of(bottomSheetContext).pop(),
        onConfirm: () {
          Navigator.of(bottomSheetContext).pop();
          _submitBooking(guestInfo);
        },
      ),
    );
  }

  /// Gửi đơn đặt phòng thực tế lên server backend (POST /api/bookings)
  Future<void> _submitBooking(GuestBookingInfo guestInfo) async {
    final hotelId = _args.hotel?.hotelId ?? '';
    final roomTypeId = _args.room?.roomTypeId ?? '';

    if (hotelId.isEmpty || roomTypeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiếu thông tin khách sạn hoặc loại phòng cần đặt.'),
          backgroundColor: AvoraTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_args.checkInDate.isEmpty || _args.checkOutDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày nhận phòng và ngày trả phòng hợp lệ.'),
          backgroundColor: AvoraTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref.read(bookingRepositoryProvider).createBooking(
            hotelId: hotelId,
            roomTypeId: roomTypeId,
            quantity: _args.rooms,
            checkInDate: _args.checkInDate,
            checkOutDate: _args.checkOutDate,
            guestName: guestInfo.fullName,
            guestPhone: guestInfo.normalizedPhone,
            specialRequest: guestInfo.combinedSpecialRequest,
            couponCode: guestInfo.couponCode,
            hotelName: _args.hotel?.name ?? _args.hotelName,
            roomName: _args.room?.name ?? _args.roomName,
          );

      if (!mounted) return;

      // Hiển thị dialog đặt phòng thành công
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BookingSuccessDialog(
          booking: result,
          args: _args,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AvoraTheme.errorRed),
              SizedBox(width: 8),
              Text(
                'Đặt phòng không thành công',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            cleanMsg,
            style: const TextStyle(fontSize: 13.5, color: AvoraTheme.textSecondary, height: 1.45),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AvoraTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelName = _args.hotel?.name ?? _args.hotelName;
    final couponState = ref.watch(bookingCouponProvider);

    return Scaffold(
      backgroundColor: AvoraTheme.pageBg,
      appBar: AppBar(
        title: const Text(
          'Thông tin khách lưu trú',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () {
            if (_isSubmitting) return;
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Stepper bar nhỏ gọn thể hiện quy trình booking
              _buildStepProgressIndicator(),

              // Nội dung cuộn chính
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    children: [
                      // Card 1: Tóm tắt thông tin phòng, giá tiền và ưu đãi
                      BookingStaySummaryCard(
                        args: _args,
                        subtotal: couponState.subtotal > 0
                            ? couponState.subtotal
                            : _args.totalPrice,
                        discountAmount: couponState.discountAmount,
                        finalTotal: couponState.totalAmount > 0
                            ? couponState.totalAmount
                            : null,
                        appliedCouponCode: couponState.appliedCoupon?.code,
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Nhập thông tin người nhận phòng (Họ tên, SĐT)
                      BookingContactInfoCard(
                        lastNameController: _lastNameController,
                        firstNameController: _firstNameController,
                        phoneController: _phoneController,
                        selectedCountryCode: _selectedCountryCode,
                        onCountryCodeChanged: (newCode) {
                          setState(() {
                            _selectedCountryCode = newCode;
                          });
                          _handleFieldChanged();
                        },
                        lastNameError: _lastNameError,
                        firstNameError: _firstNameError,
                        phoneError: _phoneError,
                        onFieldChanged: _handleFieldChanged,
                      ),
                      const SizedBox(height: 16),

                      // Card 3: Yêu cầu đặc biệt cho chỗ nghỉ
                      BookingSpecialRequestsCard(
                        hotelName: hotelName,
                        selectedRequests: _selectedRequests.toList(),
                        onToggleRequest: _toggleRequest,
                        noteController: _noteController,
                        onNoteChanged: _handleFieldChanged,
                      ),
                      const SizedBox(height: 16),

                      // Card 4: Nhập & áp dụng mã giảm giá / Coupon / Voucher
                      BookingCouponCard(
                        couponController: _couponController,
                        appliedCoupon: couponState.appliedCoupon,
                        availableCoupons: couponState.availableCoupons,
                        isApplying: couponState.isApplying,
                        couponMessage: couponState.couponMessage,
                        isSuccess: couponState.isSuccess,
                        onApplyCoupon: () {
                          ref
                              .read(bookingCouponProvider.notifier)
                              .applyCoupon(_couponController.text);
                        },
                        onRemoveCoupon: () {
                          _couponController.clear();
                          ref.read(bookingCouponProvider.notifier).removeCoupon();
                        },
                        onSelectAvailableCoupon: (code) {
                          _couponController.text = code;
                          ref
                              .read(bookingCouponProvider.notifier)
                              .applyCoupon(code);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Bar nút bấm lưu & tiếp tục
              _buildBottomActionBar(couponState),
            ],
          ),

          // Loading Overlay khi đang gửi đơn đặt phòng
          if (_isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AvoraTheme.primaryNavy),
                        SizedBox(height: 16),
                        Text(
                          'Đang xử lý đặt phòng...',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AvoraTheme.primaryNavy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vui lòng không đóng ứng dụng',
                          style: TextStyle(fontSize: 12, color: AvoraTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildStepItem(step: '1', title: 'Chọn phòng', isDone: true),
          _buildStepConnector(isDone: true),
          _buildStepItem(step: '2', title: 'Thông tin khách', isActive: true),
          _buildStepConnector(isDone: false),
          _buildStepItem(step: '3', title: 'Xác nhận', isDone: false),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    bool isDone = false,
    bool isActive = false,
  }) {
    final color = isDone
        ? AvoraTheme.successGreen
        : isActive
            ? AvoraTheme.primaryNavy
            : AvoraTheme.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone
                ? AvoraTheme.successGreen
                : isActive
                    ? AvoraTheme.primaryNavy
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  step,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AvoraTheme.textMuted,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isDone ? AvoraTheme.successGreen : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildBottomActionBar(BookingCouponState couponState) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final currentTotal = couponState.totalAmount > 0
        ? couponState.totalAmount
        : (_args.totalPrice ?? 0);
    final hasDiscount = couponState.discountAmount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AvoraTheme.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _args.room?.name ?? _args.roomName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AvoraTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${currency.format(currentTotal)} ₫',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AvoraTheme.primaryNavy,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            '-${currency.format(couponState.discountAmount)} ₫',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AvoraTheme.actionBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tiếp tục',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
