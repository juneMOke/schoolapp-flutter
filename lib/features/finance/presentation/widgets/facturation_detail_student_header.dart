import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationDetailStudentHeader extends StatelessWidget {
  final FacturationDetailIntent intent;

  const FacturationDetailStudentHeader({
    super.key,
    required this.intent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.facturationDetailStudentSectionTitle,
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingL,
            runSpacing: AppDimensions.spacingM,
            children: [
              _InfoItem(
                label: l10n.facturationDetailStudentLastName,
                value: intent.lastName,
              ),
              _InfoItem(
                label: l10n.facturationDetailStudentFirstName,
                value: intent.firstName,
              ),
              _InfoItem(
                label: l10n.facturationDetailStudentSurname,
                value: intent.surname,
              ),
              _InfoItem(
                label: l10n.facturationDetailStudentLevelGroup,
                value: intent.levelGroupName,
              ),
              _InfoItem(
                label: l10n.facturationDetailStudentLevel,
                value: intent.levelName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            value.trim().isEmpty ? l10n.facturationDetailUnknownValue : value,
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
