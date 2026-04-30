import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarNotificationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopBarNotificationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: l10n.homeTopBarNotificationsTooltip,
      onPressed: onPressed,
      icon: Stack(
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: AppTheme.textPrimaryColor,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
