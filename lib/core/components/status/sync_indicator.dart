import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État de synchronisation globale de l'application.
enum SyncStatus {
  synced,
  syncing,
  offline,
  pendingUpload,
  syncConflict,
}

/// Pastille de synchronisation pour l'AppBar.
///
/// - Stateless : l'état vient du parent.
/// - Les labels sont résolus via [AppLocalizations] dans [build].
/// - [onTap] est optionnel (bottom sheet détail, Spec 5/6).
class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onTap;

  const SyncIndicator({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final _SyncAppearance appearance = _appearanceFor(status, l10n);
    final isNeutral = appearance.color == AppColors.textMuted;

    final bgColor = isNeutral
        ? AppColors.surfaceAlt
        : appearance.color.withValues(alpha: 0.12);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(appearance.icon, size: 16, color: appearance.color),
          const SizedBox(width: 4),
          Text(
            appearance.label,
            style: AppTypography.labelSmall.copyWith(color: appearance.color),
          ),
        ],
      ),
    );

    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: content,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: pill,
      );
    }

    return pill;
  }

  _SyncAppearance _appearanceFor(SyncStatus status, AppLocalizations l10n) {
    return switch (status) {
      SyncStatus.synced => _SyncAppearance(
          icon: Icons.cloud_done,
          label: l10n.statusSynced,
          color: AppColors.success,
        ),
      SyncStatus.syncing => _SyncAppearance(
          icon: Icons.cloud_sync,
          label: l10n.statusSyncing,
          color: AppColors.info,
        ),
      SyncStatus.offline => _SyncAppearance(
          icon: Icons.cloud_off,
          label: l10n.statusOffline,
          color: AppColors.textMuted,
        ),
      SyncStatus.pendingUpload => _SyncAppearance(
          icon: Icons.cloud_upload,
          label: l10n.statusPendingUpload,
          color: AppColors.warning,
        ),
      SyncStatus.syncConflict => _SyncAppearance(
          icon: Icons.sync_problem,
          label: l10n.statusSyncConflict,
          color: AppColors.error,
        ),
    };
  }
}

class _SyncAppearance {
  final IconData icon;
  final String label;
  final Color color;

  const _SyncAppearance({
    required this.icon,
    required this.label,
    required this.color,
  });
}
