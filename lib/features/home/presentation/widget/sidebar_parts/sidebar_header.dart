import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_header_collapsed.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_parts/sidebar_header_expanded.dart';

class SidebarHeader extends StatelessWidget {
  final bool isExpanded;

  const SidebarHeader({super.key, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isExpanded
            ? HomeNavigationUiTokens.sidebarHeaderExpandedHorizontalMargin
            : HomeNavigationUiTokens.sidebarHeaderCollapsedHorizontalMargin,
        HomeNavigationUiTokens.sidebarHeaderTopMargin,
        isExpanded
            ? HomeNavigationUiTokens.sidebarHeaderExpandedHorizontalMargin
            : HomeNavigationUiTokens.sidebarHeaderCollapsedHorizontalMargin,
        0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded
            ? HomeNavigationUiTokens.sidebarHeaderExpandedHorizontalPadding
            : HomeNavigationUiTokens.sidebarHeaderCollapsedHorizontalPadding,
        vertical: HomeNavigationUiTokens.sidebarHeaderVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.08),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.textOnDark.withValues(alpha: 0.08)),
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.outCurve,
        switchOutCurve: AppMotion.inCurve,
        child: isExpanded
            ? const SidebarHeaderExpanded()
            : const SidebarHeaderCollapsed(),
      ),
    );
  }
}
