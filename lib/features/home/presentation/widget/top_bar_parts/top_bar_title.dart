import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarTitle extends StatelessWidget {
  final String title;
  final bool isPreRegistrations;
  final String? selectedSubMenuId;

  const TopBarTitle({
    super.key,
    required this.title,
    required this.isPreRegistrations,
    required this.selectedSubMenuId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedTitle = switch (selectedSubMenuId) {
      MenuConstants.classesListId => l10n.subMenuClassesList,
      _ => title,
    };
    final leadingIcon = switch (selectedSubMenuId) {
      MenuConstants.classesListId => Icons.view_list_rounded,
      MenuConstants.organisationId => Icons.grid_view_rounded,
      _ => isPreRegistrations
          ? Icons.assignment_outlined
          : Icons.dashboard_customize_outlined,
    };

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.bleuArdoise,
            borderRadius: AppRadius.brSm,
          ),
          child: Icon(
            leadingIcon,
            size: 18,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resolvedTitle.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sidebarTitle.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              if (isPreRegistrations)
                Text(
                  l10n.homeTopBarPendingSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
