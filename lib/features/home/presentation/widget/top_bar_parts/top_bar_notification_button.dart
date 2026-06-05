import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarNotificationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopBarNotificationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.homeTopBarNotificationsTooltip,
      child: Material(
        color: AppColors.textOnDark.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            HomeNavigationUiTokens.topBarActionRadius,
          ),
          side: BorderSide(color: AppColors.textOnDark.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            HomeNavigationUiTokens.topBarActionRadius,
          ),
          onTap: onPressed,
          child: SizedBox(
            width: HomeNavigationUiTokens.topBarActionSize,
            height: HomeNavigationUiTokens.topBarActionSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textOnDark,
                    size: HomeNavigationUiTokens.topBarActionIconSize,
                  ),
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.orDoux,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.bleuProfond.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
