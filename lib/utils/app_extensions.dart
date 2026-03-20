import 'package:flutter/material.dart';
import 'constants.dart';

extension StringExtension on String {
  bool get isValidEmail {
    return RegExp(AppValidation.emailPattern).hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(AppValidation.phonePattern).hasMatch(this);
  }

  Color get toColor {
    return AppColors.categoryColors[hashCode % AppColors.categoryColors.length];
  }
}

extension DoubleExtension on double {
  String get formattedPrice {
    return toStringAsFixed(2);
  }

  String get formattedPercent {
    return toStringAsFixed(1);
  }
}

extension DateTimeExtension on DateTime {
  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }
}

extension ContextExtension on BuildContext {
  void showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<T?> showCustomDialog<T>({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog<T>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelText),
            ),
          if (confirmText != null)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }
}
