import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationPageHeader extends StatelessWidget {
  const ClassesOrganisationPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    const _HeaderIcon(),
                    const SizedBox(height: AppDimensions.spacingM),
                    _HeaderContent(l10n: l10n),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _HeaderContent(l10n: l10n)),
                    const SizedBox(width: AppDimensions.spacingM),
                    const _HeaderIcon(),
                  ],
                );
        },
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  final AppLocalizations l10n;

  const _HeaderContent({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.classesOrganisationHeroTitle,
          style: AppTextStyles.pageTitle.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          l10n.classesOrganisationHeroSubtitle,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            _HeroChip(
              icon: Icons.grid_view_rounded,
              label: l10n.classesOrganisationSplitInfo,
            ),
            _HeroChip(
              icon: Icons.list_alt_rounded,
              label: l10n.classesOrganisationNonSplitInfo,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

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
      child: const Icon(
        Icons.class_outlined,
        color: AppColors.financeDetailAccent,
      ),
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
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: AppColors.indigo),
          const SizedBox(width: AppDimensions.spacingXS),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.detailInfoItemWidth,
            ),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
