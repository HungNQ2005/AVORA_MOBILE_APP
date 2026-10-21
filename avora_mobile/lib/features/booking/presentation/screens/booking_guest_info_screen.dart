import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/booking_guest_info_args.dart';
import '../../data/models/guest_booking_info.dart';
import '../widgets/booking_contact_info_card.dart';
import '../widgets/booking_info_preview_dialog.dart';
import '../widgets/booking_special_requests_card.dart';
import '../widgets/booking_stay_summary_card.dart';

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

  String _selectedCountryCode = '+84';
  final Set<String> _selectedRequests = {};

  String? _lastNameError;
  String? _firstNameError;
  String? _phoneError;
  bool _hasAttemptedSubmit = false;

  late final BookingGuestInfoArgs _args;

  @override
  void initState() {
    super.initState();
    _args = widget.args ?? const BookingGuestInfoArgs();

    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _phoneController = TextEditingController();
    _noteController = TextEditingController();

    // Tự động điền dữ liệu người dùng đăng nhập hiện tại nếu có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleRequest(String item) {
    setState(() {
      if (_selectedRequests.contains(item)) {
        _selectedRequests.remove(item);
      } else {
        _selectedRequests.add(item);
      }
    });
  }

  bool _validateInputs() {
    final lastName = _lastNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final phone = _phoneController.text.trim();
    final fullName = [lastName, firstName].where((s) => s.isNotEmpty).join(' ');

    String? lError;
    String? fError;
    String? pError;

    // Validate Họ tên người nhận phòng (Họ tên đệm & Tên)
    if (lastName.isEmpty && firstName.isEmpty) {
      lError = 'Vui lòng nhập họ và tên đệm';
      fError = 'Vui lòng nhập tên';
    } else if (lastName.isEmpty) {
      lError = 'Vui lòng nhập họ và tên đệm';
    } else if (firstName.isEmpty) {
      fError = 'Vui lòng nhập tên';
    } else if (!GuestBookingInfo.isValidGuestName(fullName)) {
      lError =
          'Họ tên phải từ 2 - 100 ký tự, có chữ cái và không chứa số hay ký tự đặc biệt.';
    }

    // Validate Số điện thoại
    if (phone.isEmpty) {
      pError = 'Vui lòng nhập số điện thoại liên hệ.';
    } else if (!GuestBookingInfo.isValidGuestPhone(phone, _selectedCountryCode)) {
      pError = _selectedCountryCode == '+84'
          ? 'Số điện thoại Việt Nam không hợp lệ (10-11 chữ số, ví dụ 0905123456).'
          : 'Số điện thoại quốc tế không hợp lệ.';
    }

    setState(() {
      _lastNameError = lError;
      _firstNameError = fError;
      _phoneError = pError;
    });

    return lError == null && fError == null && pError == null;
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

    final guestInfo = GuestBookingInfo(
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      countryCode: _selectedCountryCode,
      phone: _phoneController.text.trim(),
      selectedRequests: _selectedRequests.toList(),
      customNote: _noteController.text.trim(),
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
          _showBookingSuccessFeedback(guestInfo);
        },
      ),
    );
  }

  void _showBookingSuccessFeedback(GuestBookingInfo guestInfo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AvoraTheme.successGreen),
            SizedBox(width: 8),
            Text(
              'Đã lưu thông tin khách',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AvoraTheme.primaryNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Người đại diện: ${guestInfo.fullName}'),
            const SizedBox(height: 4),
            Text('• Số điện thoại: ${guestInfo.countryCode} ${guestInfo.phone}'),
            const SizedBox(height: 4),
            Text(
              '• Yêu cầu: ${guestInfo.combinedSpecialRequest ?? "Không có"}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.canPop()) {
                context.pop(guestInfo);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AvoraTheme.primaryNavy,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotelName = _args.hotel?.name ?? _args.hotelName;

    return Scaffold(
      backgroundColor: AvoraTheme.pageBg,
      appBar: AppBar(
        title: const Text(
          'Thông tin khách lưu trú',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () {
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
      body: Column(
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
                  // Card 1: Tóm tắt thông tin phòng & thời gian đặt
                  BookingStaySummaryCard(args: _args),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Bar nút bấm lưu & tiếp tục
          _buildBottomActionBar(),
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

  Widget _buildBottomActionBar() {
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
                  const Text(
                    'Usecase: Nhập thông tin khách',
                    style: TextStyle(
                      fontSize: 11,
                      color: AvoraTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _args.room?.name ?? _args.roomName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AvoraTheme.primaryNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _handleSubmit,
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
              child: const Row(
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
