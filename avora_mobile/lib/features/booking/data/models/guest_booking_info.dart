import 'package:equatable/equatable.dart';

/// Data model đại diện cho thông tin khách lưu trú và yêu cầu đặc biệt.
/// Đồng bộ 1:1 với backend `booking.validation.js` và `ContactInfoCard.jsx` / `SpecialRequestsCard.jsx`.
class GuestBookingInfo extends Equatable {
  final String lastName;
  final String firstName;
  final String countryCode;
  final String phone;
  final List<String> selectedRequests;
  final String customNote;
  final String? couponCode;
  final num? discountAmount;

  const GuestBookingInfo({
    this.lastName = '',
    this.firstName = '',
    this.countryCode = '+84',
    this.phone = '',
    this.selectedRequests = const [],
    this.customNote = '',
    this.couponCode,
    this.discountAmount,
  });

  /// Họ và tên đầy đủ kết hợp từ Họ đệm và Tên
  String get fullName {
    final l = lastName.trim();
    final f = firstName.trim();
    if (l.isEmpty && f.isEmpty) return '';
    if (l.isEmpty) return f;
    if (f.isEmpty) return l;
    return '$l $f';
  }

  /// Chuỗi tổng hợp toàn bộ yêu cầu đặc biệt gửi về backend
  String? get combinedSpecialRequest {
    final list = <String>[...selectedRequests];
    if (customNote.trim().isNotEmpty) {
      list.add(customNote.trim());
    }
    if (list.isEmpty) return null;
    return list.join('; ');
  }

  /// Chuẩn hóa số điện thoại theo quy chuẩn backend Avora
  String get normalizedPhone {
    final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
    final code = countryCode.trim();

    if (code == '+84') {
      var vnDigits = cleanDigits;
      if (vnDigits.startsWith('84') && vnDigits.length > 9) {
        vnDigits = vnDigits.substring(2);
      }
      vnDigits = vnDigits.replaceFirst(RegExp(r'^0+'), '');
      return vnDigits.isNotEmpty ? '0$vnDigits' : phone.trim();
    } else {
      final intlDigits = cleanDigits.replaceFirst(RegExp(r'^0+'), '');
      return intlDigits.isNotEmpty ? '$code$intlDigits' : phone.trim();
    }
  }

  // ─── Backend Validation Constants & Rules ─────────────────────────────────
  static const int maxGuestNameLength = 100;
  static const int minGuestNameLength = 2;
  static const int maxSpecialRequestLength = 1000;
  static const int maxSpecialRequestOptions = 10;

  /// Regex hỗ trợ 100% tiếng Việt có dấu, khoảng trắng, dấu nháy đơn, gạch nối
  static final RegExp guestNameRegex = RegExp(
    r'^(?=.*[\p{L}])[\p{L}\s\x27\.\-]{2,100}$',
    unicode: true,
  );

  /// Kiểm tra tính hợp lệ của họ và tên khách
  static bool isValidGuestName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < minGuestNameLength ||
        trimmed.length > maxGuestNameLength) {
      return false;
    }
    return guestNameRegex.hasMatch(trimmed);
  }

  /// Kiểm tra tính hợp lệ của số điện thoại
  static bool isValidGuestPhone(String phone, String countryCode) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return false;
    if (!RegExp(r'^\+?[\d\s\-().]+$').hasMatch(trimmed)) return false;

    final cleanDigits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (countryCode == '+84') {
      var vn = cleanDigits;
      if (vn.startsWith('84') && vn.length > 9) vn = vn.substring(2);
      vn = vn.replaceFirst(RegExp(r'^0+'), '');
      return RegExp(r'^0\d{9,10}$').hasMatch('0$vn');
    }

    final intl = cleanDigits.replaceFirst(RegExp(r'^0+'), '');
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch('$countryCode$intl');
  }

  /// 5 yêu cầu đặc biệt tiêu chuẩn từ hệ thống website Avora
  static const List<String> standardRequests = [
    'Phòng không hút thuốc',
    '1 giường lớn đôi King-size',
    'Nhận phòng sớm (~12:00)',
    'Cũi / nôi cho trẻ sơ sinh',
    'Phòng vị trí yên tĩnh, gần biển',
  ];

  /// Danh sách mã quốc gia hỗ trợ
  static const List<CountryCodeItem> supportedCountries = [
    CountryCodeItem(code: '+84', countryName: 'Việt Nam', flag: '🇻🇳', shortName: 'VN'),
    CountryCodeItem(code: '+1', countryName: 'Hoa Kỳ', flag: '🇺🇸', shortName: 'US'),
    CountryCodeItem(code: '+81', countryName: 'Nhật Bản', flag: '🇯🇵', shortName: 'JP'),
    CountryCodeItem(code: '+82', countryName: 'Hàn Quốc', flag: '🇰🇷', shortName: 'KR'),
    CountryCodeItem(code: '+65', countryName: 'Singapore', flag: '🇸🇬', shortName: 'SG'),
    CountryCodeItem(code: '+66', countryName: 'Thái Lan', flag: '🇹🇭', shortName: 'TH'),
    CountryCodeItem(code: '+886', countryName: 'Đài Loan', flag: '🇹🇼', shortName: 'TW'),
    CountryCodeItem(code: '+44', countryName: 'Anh Quốc', flag: '🇬🇧', shortName: 'UK'),
    CountryCodeItem(code: '+61', countryName: 'Úc', flag: '🇦🇺', shortName: 'AU'),
    CountryCodeItem(code: '+33', countryName: 'Pháp', flag: '🇫🇷', shortName: 'FR'),
  ];

  GuestBookingInfo copyWith({
    String? lastName,
    String? firstName,
    String? countryCode,
    String? phone,
    List<String>? selectedRequests,
    String? customNote,
    String? couponCode,
    num? discountAmount,
  }) {
    return GuestBookingInfo(
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      selectedRequests: selectedRequests ?? this.selectedRequests,
      customNote: customNote ?? this.customNote,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  @override
  List<Object?> get props => [
        lastName,
        firstName,
        countryCode,
        phone,
        selectedRequests,
        customNote,
        couponCode,
        discountAmount,
      ];
}

class CountryCodeItem extends Equatable {
  final String code;
  final String countryName;
  final String flag;
  final String shortName;

  const CountryCodeItem({
    required this.code,
    required this.countryName,
    required this.flag,
    required this.shortName,
  });

  @override
  List<Object?> get props => [code, countryName, flag, shortName];
}
