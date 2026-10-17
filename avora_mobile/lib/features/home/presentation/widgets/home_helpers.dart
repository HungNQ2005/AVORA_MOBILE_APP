import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Định dạng tiền tệ dùng chung cho màn hình Home.
final NumberFormat homeCurrencyFormatter = NumberFormat('#,###', 'vi_VN');

/// Hiển thị SnackBar nổi dùng chung cho các widget của Home.
void showHomeSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
