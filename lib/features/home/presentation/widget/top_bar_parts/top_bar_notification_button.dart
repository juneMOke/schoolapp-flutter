import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class TopBarNotificationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopBarNotificationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
