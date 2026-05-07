import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

class AcademicInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final Widget child;

  const AcademicInfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppElevation.surface2.copyWith(borderRadius: AppRadius.brSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
        ],
      ),
    );
  }
}
