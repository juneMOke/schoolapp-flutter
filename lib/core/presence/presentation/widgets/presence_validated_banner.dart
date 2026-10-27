import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_icon_medallion.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le jour validé, en tête de fiche : le médaillon et le badge « Validé »,
/// qui et quand, où en est l'envoi, les trois compteurs de la modale de
/// validation — et Rouvrir.
class PresenceValidatedBanner extends StatelessWidget {
  final String title;

  /// « Par Mme Ilunga · 29 sept. 2026 · 08:05 », ou seulement le moment.
  final String? byLine;
  final int present;
  final int late;
  final int absent;
  final RecordSyncState sync;

  /// `null` : pas de réouverture (mois clos, droit manquant).
  final VoidCallback? onReopen;

  /// `null` : pas de reprise d'envoi proposée.
  final VoidCallback? onRetry;

  const PresenceValidatedBanner({
    super.key,
    required this.title,
    required this.byLine,
    required this.present,
    required this.late,
    required this.absent,
    required this.sync,
    required this.onReopen,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.presenceMarkPresentSoft,
      borderRadius: AppRadius.brLg,
      border: Border.all(
        color: AppColors.presenceMarkPresentBorder,
        width: AppDimensions.presenceMarkBorderWidth,
      ),
      boxShadow: AppElevation.shadowCard,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            _Heading(title: title, byLine: byLine),
            _Actions(sync: sync, onRetry: onRetry, onReopen: onReopen),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PresenceCountRow(present: present, late: late, absent: absent),
      ],
    ),
  );
}

/// Le médaillon, le titre et la ligne « par … · quand ».
class _Heading extends StatelessWidget {
  final String title;
  final String? byLine;

  const _Heading({required this.title, required this.byLine});

  @override
  Widget build(BuildContext context) {
    final byLine = this.byLine;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EteeloIconMedallion(
          icon: Icons.verified_outlined,
          color: AppColors.presenceMarkPresentInk,
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.presenceMarkPresentInk,
                ),
              ),
              if (byLine != null)
                Text(
                  byLine,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le badge « Validé », l'état de l'envoi, Réessayer et Rouvrir.
class _Actions extends StatelessWidget {
  final RecordSyncState sync;
  final VoidCallback? onRetry;
  final VoidCallback? onReopen;

  const _Actions({
    required this.sync,
    required this.onRetry,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onRetry = this.onRetry;
    final onReopen = this.onReopen;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusBadge(
          icon: Icons.task_alt,
          label: l10n.presenceMarkValidatedBadge,
          color: AppColors.presenceMarkPresentInk,
          style: StatusBadgeStyle.filled,
        ),
        RecordSyncPill(state: sync),
        if (onRetry != null && sync == RecordSyncState.failed)
          EteeloButton.ghost(
            label: l10n.presenceMarkRetry,
            icon: Icons.refresh,
            onPressed: onRetry,
            fullWidth: false,
          ),
        if (onReopen != null)
          EteeloButton.secondary(
            label: l10n.presenceMarkReopen,
            icon: Icons.lock_open,
            onPressed: onReopen,
            fullWidth: false,
          ),
      ],
    );
  }
}
