import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le jour validé : qui, quand, combien, où en est l'envoi — et Rouvrir.
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byLine = this.byLine;
    final onReopen = this.onReopen;
    final onRetry = this.onRetry;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.presenceMarkPresentSoft,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.presenceMarkPresentBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_outlined,
                color: AppColors.presenceMarkPresentInk,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.presenceMarkPresentInk,
                      ),
                    ),
                    Text(
                      [
                        ?byLine,
                        l10n.presenceMarkValidatedCounts(present, late, absent),
                      ].join(' · '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RecordSyncPill(state: sync),
              if (onRetry != null && sync == RecordSyncState.failed)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: EteeloButton.ghost(
                    label: l10n.presenceMarkRetry,
                    icon: Icons.refresh,
                    onPressed: onRetry,
                    fullWidth: false,
                  ),
                ),
              if (onReopen != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: EteeloButton.secondary(
                    label: l10n.presenceMarkReopen,
                    icon: Icons.lock_open,
                    onPressed: onReopen,
                    fullWidth: false,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
