import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class FinanceStudentHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String unknownValue;
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;
  final String levelLabel;
  final String levelGroupLabel;
  final bool showFeatureChips;
  final String paymentsChipLabel;
  final String chargesChipLabel;

  const FinanceStudentHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.unknownValue,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
    required this.levelLabel,
    required this.levelGroupLabel,
    this.showFeatureChips = true,
    required this.paymentsChipLabel,
    required this.chargesChipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = [lastName, firstName, surname]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.financeDetailInfoSurface,
            AppColors.financeDetailCard,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.financeDetailCardShadowBlur,
            offset: Offset(0, AppDimensions.financeDetailCardShadowOffsetY),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxWidth < AppDimensions.detailCompactBreakpoint;

          final metaBadges = Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              if (levelGroupName.trim().isNotEmpty)
                _MetaBadge(
                  label: levelGroupLabel,
                  value: levelGroupName,
                  accent: AppColors.financeDetailAmber,
                  accentSoft: AppColors.financeDetailAmberSoft,
                ),
              if (levelName.trim().isNotEmpty)
                _MetaBadge(
                  label: levelLabel,
                  value: levelName,
                  accent: AppColors.financeDetailTeal,
                  accentSoft: AppColors.financeDetailTealSoft,
                ),
            ],
          );

          final featureChips = Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              _FeatureChip(
                label: paymentsChipLabel,
                icon: Icons.payments_outlined,
                accent: AppColors.financeDetailPaymentsAccent,
                accentSoft: AppColors.financeDetailPaymentsAccentSoft,
              ),
              _FeatureChip(
                label: chargesChipLabel,
                icon: Icons.receipt_long_outlined,
                accent: AppColors.financeDetailChargesAccent,
                accentSoft: AppColors.financeDetailChargesAccentSoft,
              ),
            ],
          );

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                fullName.isEmpty ? unknownValue : fullName,
                style: AppTextStyles.detailHeroTitle.copyWith(
                  color: AppColors.financeDetailAccent,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              metaBadges,
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                subtitle,
                style: AppTextStyles.detailHeroSubtitle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (showFeatureChips) ...[
                const SizedBox(height: AppDimensions.spacingM),
                featureChips,
              ],
            ],
          );

          final avatar = Container(
            width: AppDimensions.detailHeroAvatarSize,
            height: AppDimensions.detailHeroAvatarSize,
            decoration: BoxDecoration(
              color: AppColors.financeDetailAccentSoft,
              borderRadius: BorderRadius.circular(AppDimensions.spacingXL),
              border: Border.all(
                color: AppColors.financeDetailAccent.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: AppDimensions.detailHeaderIconSize,
              color: AppColors.financeDetailAccent,
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(height: AppDimensions.spacingM),
                textContent,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: textContent),
            ],
          );
        },
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Color accentSoft;

  const _MetaBadge({
    required this.label,
    required this.value,
    required this.accent,
    required this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingL),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label · ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.caption.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Color accentSoft;

  const _FeatureChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingL),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: accent),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(label, style: AppTextStyles.badge.copyWith(color: accent)),
        ],
      ),
    );
  }
}
