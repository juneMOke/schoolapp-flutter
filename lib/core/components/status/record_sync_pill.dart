import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Où est la donnée : une pastille de couleur et son libellé. Orange sur la
/// tablette, vert au serveur, rouge refusée.
class RecordSyncPill extends StatelessWidget {
  final RecordSyncState state;

  const RecordSyncPill({super.key, required this.state});

  static Color colorOf(RecordSyncState state) => switch (state) {
    RecordSyncState.synced => AppColors.success,
    RecordSyncState.pending => AppColors.warning,
    RecordSyncState.failed => AppColors.error,
  };

  /// Encre du libellé : le [AppColors.warning] fonde la pastille mais ne
  /// s'écrit pas sur blanc.
  static Color inkOf(RecordSyncState state) => switch (state) {
    RecordSyncState.synced => AppColors.success,
    RecordSyncState.pending => AppColors.warningInk,
    RecordSyncState.failed => AppColors.error,
  };

  /// « Synchronisé », « Sur la tablette », « Échec d'envoi ».
  static String label(AppLocalizations l10n, RecordSyncState state) =>
      switch (state) {
        RecordSyncState.synced => l10n.recordSyncSynced,
        RecordSyncState.pending => l10n.recordSyncPending,
        RecordSyncState.failed => l10n.recordSyncFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RecordSyncDot(state: state),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label(l10n, state),
            style: AppTypography.labelSmall.copyWith(color: inkOf(state)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// La seule pastille, sans libellé — posée sur l'avatar.
class RecordSyncDot extends StatelessWidget {
  final RecordSyncState state;
  final double size;

  const RecordSyncDot({super.key, required this.state, this.size = 8});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: RecordSyncPill.colorOf(state),
      shape: BoxShape.circle,
    ),
  );
}
