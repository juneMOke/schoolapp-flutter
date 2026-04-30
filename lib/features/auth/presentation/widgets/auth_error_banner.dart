import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS,
          vertical: AppDimensions.spacingS,
        ),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          border: Border.all(color: colorScheme.error),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: AppDimensions.detailMiniIconSize,
              color: colorScheme.error,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
