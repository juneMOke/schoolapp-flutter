import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/components/status/last_sync_label.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État de synchronisation globale de l'application.
///
/// [authRequired] (V1.1) : le réseau est là mais la session ne peut pas
/// authentifier ses appels (session ouverte offline sans jetons ni consigne) —
/// la boucle ne flushe PAS (zéro 401, zéro tentative consommée) tant qu'un
/// login online n'a pas eu lieu.
///
/// [partiallySynced] (ADR-015 F1) : la file de push est vide, mais le dernier
/// cycle de **lecture** n'a pas tout ramené. Ce n'est **pas** une panne, et
/// c'est ce qui le distingue de [syncConflict] : rien n'est perdu, rien n'est à
/// reprendre, des domaines entiers sont simplement absents du cache local. Sans
/// ce statut la pastille affichait « À jour » pendant qu'un écran voisin
/// expliquait un vide par une synchronisation à venir qui n'arriverait jamais.
enum SyncStatus {
  synced,
  partiallySynced,
  syncing,
  offline,
  pendingUpload,
  syncConflict,
  authRequired,
}

/// Pastille de synchronisation pour l'AppBar.
///
/// - Stateless : l'état vient du parent.
/// - Les labels sont résolus via [AppLocalizations] dans [build].
/// - [onTap] est optionnel (bottom sheet détail, Spec 5/6).
/// - [lastSyncAtMs] (epoch ms, heure **serveur**) affiche un texte relatif
///   après le libellé de statut (" · il y a N min") quand connu — absent tant
///   qu'aucune synchro n'a encore ramené de données.
class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final int? lastSyncAtMs;
  final VoidCallback? onTap;

  const SyncIndicator({
    super.key,
    required this.status,
    this.lastSyncAtMs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final _SyncAppearance appearance = _appearanceFor(status, l10n);
    final isNeutral = appearance.color == AppColors.textMuted;
    final relative = _relativeLastSync(l10n);

    final bgColor = isNeutral
        ? AppColors.surfaceAlt
        : appearance.color.withValues(alpha: 0.12);

    final label = relative == null
        ? appearance.label
        : '${appearance.label} · $relative';

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(appearance.icon, size: 16, color: appearance.color),
          const SizedBox(width: 4),
          Text(
            label,
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

  /// Texte relatif depuis [lastSyncAtMs], `null` si aucune synchro connue.
  ///
  /// Le calcul vit dans [relativeLastSyncLabel] : la caisse l'affiche aussi,
  /// sous son total, et deux formulations du même écoulé finiraient par se
  /// contredire à quelques minutes près.
  String? _relativeLastSync(AppLocalizations l10n) =>
      relativeLastSyncLabel(l10n, lastSyncAtMs);

  _SyncAppearance _appearanceFor(SyncStatus status, AppLocalizations l10n) {
    return switch (status) {
      SyncStatus.synced => _SyncAppearance(
        icon: Icons.cloud_done,
        label: l10n.statusSynced,
        color: AppColors.success,
      ),
      // Teinte NEUTRE, jamais l'ambre ni le rouge : un compte au périmètre
      // étroit est dans cet état en permanence et tout va bien pour lui. La
      // pastille dit qu'il manque quelque chose, elle n'accuse pas une panne.
      SyncStatus.partiallySynced => _SyncAppearance(
        icon: Icons.cloud_done_outlined,
        label: l10n.statusPartiallySynced,
        color: AppColors.textMuted,
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
      SyncStatus.authRequired => _SyncAppearance(
        icon: Icons.lock_person_outlined,
        label: l10n.statusAuthRequired,
        color: AppColors.warning,
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
