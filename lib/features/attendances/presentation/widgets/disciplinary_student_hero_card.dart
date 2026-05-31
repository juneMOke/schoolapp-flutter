import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class DisciplinaryStudentHeroCard extends StatelessWidget {
  final String unknownValue;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String levelName;
  final String levelGroupName;
  final String levelLabel;
  final String levelGroupLabel;

  const DisciplinaryStudentHeroCard({
    super.key,
    required this.unknownValue,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.levelName,
    required this.levelGroupName,
    required this.levelLabel,
    required this.levelGroupLabel,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = [
      lastName,
      middleName,
      firstName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    final displayName = fullName.isEmpty ? unknownValue : fullName;
    final displayLevelName = levelName.trim().isEmpty
        ? unknownValue
        : levelName.trim();
    final displayLevelGroupName = levelGroupName.trim().isEmpty
        ? unknownValue
        : levelGroupName.trim();
    final avatarInitial = [lastName, middleName, firstName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim().characters.first.toUpperCase())
        .cast<String>()
        .firstWhere((_) => true, orElse: () => '?');

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
            color: AppColors.disciplinaryDetailShadow,
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
              _MetaBadge(
                label: levelGroupLabel,
                value: displayLevelGroupName,
                accent: AppColors.financeDetailAmber,
                accentSoft: AppColors.financeDetailAmberSoft,
              ),
              _MetaBadge(
                label: levelLabel,
                value: displayLevelName,
                accent: AppColors.financeDetailTeal,
                accentSoft: AppColors.financeDetailTealSoft,
              ),
            ],
          );

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTextStyles.detailHeroTitle.copyWith(
                  color: AppColors.financeDetailAccent,
                ),
                maxLines: isCompact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              metaBadges,
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
            child: Center(
              child: Text(
                avatarInitial,
                style: AppTextStyles.detailHeroTitle.copyWith(
                  color: AppColors.financeDetailAccent,
                  fontSize: AppDimensions.spacingL,
                  height: 1,
                ),
              ),
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
