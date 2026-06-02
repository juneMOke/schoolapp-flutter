import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarLeadingMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopBarLeadingMenuButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(
        left: HomeNavigationUiTokens.topBarActionsGap,
      ),
      child: Material(
        color: AppColors.textOnDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          HomeNavigationUiTokens.topBarActionRadius,
        ),
        child: IconButton(
          tooltip: l10n.homeSidebarExpandTooltip,
          onPressed: onPressed,
          icon: const Icon(
            Icons.menu_rounded,
            size: HomeNavigationUiTokens.topBarActionIconSize + 2,
          ),
        ),
      ),
    );
  }
}
