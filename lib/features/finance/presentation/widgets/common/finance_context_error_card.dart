import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';

/// Carte standard d'erreur de contexte pour les pages detail/create de Finance.
class FinanceContextErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final Color borderColor;

  const FinanceContextErrorCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.accent = AppColors.financeDetailAccent,
    this.accentSoft = AppColors.financeDetailAccentSoft,
    this.borderColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return FinanceSectionCard(
      backgroundColor: AppColors.financeDetailCard,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: icon,
            title: title,
            accent: accent,
            accentSoft: accentSoft,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
