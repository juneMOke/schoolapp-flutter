import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// En-tete standard des sections Finance (badge icone + titre + sous-titre).
class FinanceSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final Color accentSoft;

  const FinanceSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    required this.accentSoft,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          subtitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: AppDimensions.spacingL,
          height: AppDimensions.spacingL,
          decoration: BoxDecoration(
            color: accentSoft,
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
          child: Icon(
            icon,
            size: AppDimensions.detailMiniIconSize,
            color: accent,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
