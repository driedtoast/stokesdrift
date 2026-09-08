import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final bool loading;
  final bool disabled;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.loading = false,
    this.disabled = false,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    final isSecondary = variant == AppButtonVariant.secondary;
    final isGhost = variant == AppButtonVariant.ghost;

    final bgColor = isPrimary
        ? AppColors.tertiary
        : isSecondary
            ? AppColors.secondary
            : Colors.transparent;

    final textColor = isPrimary || isSecondary
        ? AppColors.onPrimary
        : AppColors.secondary;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: (disabled || loading) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isGhost ? Colors.transparent : bgColor,
          foregroundColor: textColor,
          side: isGhost
              ? const BorderSide(color: AppColors.secondary, width: 1.5)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          minimumSize: const Size.fromHeight(48),
          disabledBackgroundColor: isGhost ? Colors.transparent : bgColor.withValues(alpha: 0.4),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Text(
                title,
                style: AppTypography.label.copyWith(
                  color: textColor,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, ghost }