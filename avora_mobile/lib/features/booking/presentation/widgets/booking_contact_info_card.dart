import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/guest_booking_info.dart';

/// Card 1: Nhập thông tin chi tiết người nhận phòng (Họ tên, SĐT)
/// Thiết kế chuẩn Material 3 đồng bộ 1:1 với `ContactInfoCard.jsx` trên Website Avora.
class BookingContactInfoCard extends StatelessWidget {
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController phoneController;
  final String selectedCountryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final String? lastNameError;
  final String? firstNameError;
  final String? phoneError;
  final VoidCallback? onFieldChanged;

  const BookingContactInfoCard({
    super.key,
    required this.lastNameController,
    required this.firstNameController,
    required this.phoneController,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
    this.lastNameError,
    this.firstNameError,
    this.phoneError,
    this.onFieldChanged,
  });

  void _showCountryCodePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Chọn mã quốc gia',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        color: AvoraTheme.textMuted,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AvoraTheme.cardBorder),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: GuestBookingInfo.supportedCountries.length,
                    separatorBuilder: (separatorContext, separatorIndex) =>
                        const Divider(height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (ctx, index) {
                      final item = GuestBookingInfo.supportedCountries[index];
                      final isSelected = item.code == selectedCountryCode;

                      return ListTile(
                        leading: Text(
                          item.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          item.countryName,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AvoraTheme.primaryNavy
                                : AvoraTheme.textPrimary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.code,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AvoraTheme.primaryNavy
                                    : AvoraTheme.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AvoraTheme.actionBlue,
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          onCountryCodeChanged(item.code);
                          Navigator.of(bottomSheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  CountryCodeItem get _currentCountryItem {
    return GuestBookingInfo.supportedCountries.firstWhere(
      (c) => c.code == selectedCountryCode,
      orElse: () => GuestBookingInfo.supportedCountries.first,
    );
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
                    Icons.person_pin_rounded,
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
                        'Thông tin người nhận phòng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Họ tên và số điện thoại người đại diện nhận phòng tại quầy lễ tân khách sạn.',
                        style: TextStyle(
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

            const SizedBox(height: 18),
            const Divider(height: 1, color: AvoraTheme.cardBorder),
            const SizedBox(height: 18),

            // Form Grid: Họ và tên đệm & Tên (2 ô trên 1 hàng ở mobile rộng hoặc 2 ô thẳng hàng)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Họ và tên đệm
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Họ và tên đệm', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          hintText: 'Ví dụ: Nguyễn',
                          errorText: lastNameError,
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        ),
                        onChanged: (_) => onFieldChanged?.call(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Tên
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tên', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          hintText: 'Ví dụ: Văn An',
                          errorText: firstNameError,
                        ),
                        onChanged: (_) => onFieldChanged?.call(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Số điện thoại liên hệ với mã quốc gia tích hợp
            _buildLabel('Số điện thoại liên hệ', isRequired: true),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nút chọn mã vùng quốc gia
                  InkWell(
                    onTap: () => _showCountryCodePicker(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: phoneError != null
                              ? AvoraTheme.errorRed
                              : AvoraTheme.inputBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentCountryItem.flag,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentCountryItem.code,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AvoraTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AvoraTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Ô nhập SĐT
                  Expanded(
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\+]')),
                      ],
                      decoration: _buildInputDecoration(
                        hintText: '0905 123 456',
                        errorText: phoneError,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      ),
                      onChanged: (_) => onFieldChanged?.call(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AvoraTheme.textBody,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AvoraTheme.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    String? errorText,
    Widget? prefixIcon,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13.5,
        color: Color(0xFF9CA3AF),
      ),
      errorText: hasError ? errorText : null,
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        fontSize: 11.5,
        color: AvoraTheme.errorRed,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
      prefixIconColor: hasError ? AvoraTheme.errorRed : AvoraTheme.textMuted,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AvoraTheme.inputBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AvoraTheme.inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AvoraTheme.primaryNavy, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AvoraTheme.errorRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AvoraTheme.errorRed, width: 1.8),
      ),
    );
  }
}
