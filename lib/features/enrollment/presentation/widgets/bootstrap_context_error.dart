import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class BootstrapContextError extends StatelessWidget {
  final VoidCallback onLogout;

  const BootstrapContextError({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(20),
        decoration: AppElevation.surface3.copyWith(
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  l10n.bootstrapContextUnavailableTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.bootstrapContextUnavailableMessage,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.signOutAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
