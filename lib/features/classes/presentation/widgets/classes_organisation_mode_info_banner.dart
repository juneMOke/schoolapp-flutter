import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationModeInfoBanner extends StatelessWidget {
  final bool isSplit;

  const ClassesOrganisationModeInfoBanner({super.key, required this.isSplit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.classesInfoBannerSurface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.classesInfoBannerBorder),
      ),
      child: Row(
        children: [
          Icon(
            isSplit ? Icons.grid_view_rounded : Icons.list_alt_rounded,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.indigo,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              isSplit
                  ? l10n.classesOrganisationSplitInfo
                  : l10n.classesOrganisationNonSplitInfo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
