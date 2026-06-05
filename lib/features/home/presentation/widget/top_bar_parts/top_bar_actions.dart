import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_logout_button.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_notification_button.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_profile_menu_button.dart';

class TopBarActions extends StatelessWidget {
  final bool isCompact;

  const TopBarActions({super.key, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TopBarNotificationButton(onPressed: () {}),
        const SizedBox(width: HomeNavigationUiTokens.topBarActionsGap),
        if (!isCompact) ...[
          const TopBarLogoutButton(),
          const SizedBox(width: HomeNavigationUiTokens.topBarActionsGap),
          Container(
            width: HomeNavigationUiTokens.topBarDividerWidth,
            height: HomeNavigationUiTokens.topBarDividerHeight,
            color: AppColors.textOnDark.withValues(alpha: 0.18),
          ),
          const SizedBox(width: HomeNavigationUiTokens.topBarActionsGap),
        ],
        const TopBarProfileMenuButton(),
        SizedBox(
          width: isCompact
              ? HomeNavigationUiTokens.topBarCompactActionsEndPadding
              : HomeNavigationUiTokens.topBarDesktopActionsEndPadding,
        ),
      ],
    );
  }
}
