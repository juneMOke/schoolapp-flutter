import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarTitle extends StatelessWidget {
  final String? moduleTitle;
  final String title;
  final bool isPreRegistrations;
  final String? selectedSubMenuId;

  /// En compact (mobile), l'icône de tête est masquée : on garde le burger
  /// (leading de l'AppBar) puis directement le titre.
  final bool isCompact;

  const TopBarTitle({
    super.key,
    required this.moduleTitle,
    required this.title,
    required this.isPreRegistrations,
    required this.selectedSubMenuId,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedTitle = switch (selectedSubMenuId) {
      MenuConstants.classesListId => l10n.subMenuClassesList,
      _ => title,
    };
    final leadingIcon = switch (selectedSubMenuId) {
      MenuConstants.accueilId => Icons.home_outlined,
      MenuConstants.classesListId => Icons.view_list_rounded,
      MenuConstants.organisationId => Icons.grid_view_rounded,
      _ =>
        isPreRegistrations
            ? Icons.assignment_outlined
            : Icons.dashboard_customize_outlined,
    };

    return Row(
      children: [
        // Mobile : icône de tête masquée → burger puis titre directement.
        if (!isCompact) ...[
          Container(
            width: HomeNavigationUiTokens.topBarTitleLeadingBoxSize,
            height: HomeNavigationUiTokens.topBarTitleLeadingBoxSize,
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withValues(alpha: 0.09),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(
              leadingIcon,
              size: HomeNavigationUiTokens.topBarTitleLeadingIconSize,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(width: HomeNavigationUiTokens.topBarTitleGap),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (moduleTitle != null)
                Text(
                  moduleTitle!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.orDoux,
                    letterSpacing:
                        HomeNavigationUiTokens.topBarTitleLetterSpacing,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                resolvedTitle.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sidebarTitle.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: HomeNavigationUiTokens.topBarTitleFontSize,
                  height: HomeNavigationUiTokens.topBarTitleLineHeight,
                ),
              ),
              if (isPreRegistrations)
                Text(
                  l10n.homeTopBarPendingSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.76),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
