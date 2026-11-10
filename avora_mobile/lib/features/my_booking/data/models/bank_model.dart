import 'package:equatable/equatable.dart';

/// Model đại diện cho ngân hàng hỗ trợ nhận tiền hoàn (từ m_system_code & VietQR)
class BankModel extends Equatable {
  final String bankCd;
  final String codeName;
  final String? binCode;
  final String? bin;
  final String? code;
  final String name;
  final String shortName;
  final String? logoUrl;

  const BankModel({
    required this.bankCd,
    required this.codeName,
    this.binCode,
    this.bin,
    this.code,
    required this.name,
    required this.shortName,
    this.logoUrl,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    final rawShort = (json['short_name'] ?? json['code_name'] ?? json['name'] ?? '').toString();
    final rawName = (json['name'] ?? json['code_name'] ?? '').toString();
    final rawBin = json['bin']?.toString() ?? json['bin_code']?.toString();

    return BankModel(
      bankCd: (json['bank_cd'] ?? json['code_cd'] ?? '').toString(),
      codeName: (json['code_name'] ?? '').toString(),
      binCode: json['bin_code']?.toString(),
      bin: rawBin,
      code: json['code']?.toString() ?? json['code_name']?.toString(),
      name: rawName.isNotEmpty ? rawName : rawShort,
      shortName: rawShort.isNotEmpty ? rawShort : rawName,
      logoUrl: json['logo_url']?.toString() ?? json['logo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'bank_cd': bankCd,
        'code_name': codeName,
        'bin_code': binCode,
        'bin': bin,
        'code': code,
        'name': name,
        'short_name': shortName,
        'logo_url': logoUrl,
      };

  String get effectiveBin => bin ?? binCode ?? '';

  String get displayName => shortName.isNotEmpty ? shortName : name;

  String get fullNameWithShort {
    if (shortName.isNotEmpty && name.isNotEmpty && shortName != name) {
      return '$name ($shortName)';
    }
    return name.isNotEmpty ? name : shortName;
  }

  /// Khớp từ khóa tìm kiếm (tên, tên viết tắt, mã BIN, mã ngân hàng)
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return name.toLowerCase().contains(q) ||
        shortName.toLowerCase().contains(q) ||
        (code?.toLowerCase().contains(q) ?? false) ||
        codeName.toLowerCase().contains(q) ||
        bankCd.toLowerCase().contains(q) ||
        effectiveBin.contains(q);
  }

  @override
  List<Object?> get props => [
        bankCd,
        codeName,
        binCode,
        bin,
        code,
        name,
        shortName,
        logoUrl,
      ];
}
