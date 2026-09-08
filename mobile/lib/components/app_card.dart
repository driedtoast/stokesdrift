import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AppCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title!, style: AppTypography.h2.copyWith(color: AppColors.primary)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!,
                      style: AppTypography.body.copyWith(
                          color: AppColors.secondary, fontSize: 13)),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}