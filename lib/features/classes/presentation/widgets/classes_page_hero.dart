import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

class ClassesPageHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<ClassesPageHeroChipData> chips;
  final Color titleColor;

  const ClassesPageHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.chips,
    this.titleColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.classesHeroGradientStart,
            AppColors.classesHeroGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.classesOrganisationShadowOffsetY),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          return isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroIcon(icon: icon),
                    const SizedBox(height: AppDimensions.spacingM),
                    _HeroContent(
                      title: title,
                      subtitle: subtitle,
                      chips: chips,
                      titleColor: titleColor,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _HeroContent(
                        title: title,
                        subtitle: subtitle,
                        chips: chips,
                        titleColor: titleColor,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    _HeroIcon(icon: icon),
                  ],
                );
        },
      ),
    );
  }
}

class ClassesPageHeroChipData {
  final IconData icon;
  final String label;

  const ClassesPageHeroChipData({required this.icon, required this.label});
}

class _HeroContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ClassesPageHeroChipData> chips;
  final Color titleColor;

  const _HeroContent({
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.pageTitle.copyWith(color: titleColor)),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: chips
                .map((chip) => _HeroChip(icon: chip.icon, label: chip.label))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;

  const _HeroIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.detailHeroAvatarSize,
      height: AppDimensions.detailHeroAvatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.financeDetailAccentSoft,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.spacingM,
            offset: Offset(0, AppDimensions.spacingS),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.financeDetailAccent),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.indigo,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.detailInfoItemWidth,
            ),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
