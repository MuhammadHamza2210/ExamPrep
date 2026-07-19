import 'package:flutter/material.dart';
import 'package:examprep/core/icons.dart';
import '../../app/theme.dart';

/// Rounded, coloured toast with slide+fade (Material's built-in animation).
class AppSnack {
  static void show(
    BuildContext context,
    String message, {
    bool success = true,
  }) {
    final color = success ? AppColors.accent : AppColors.danger;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          elevation: 6,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              Icon(
                success ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
