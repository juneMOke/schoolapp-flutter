import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/sync_aggregate_labels.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une écriture À MOI que le moteur retient, et pourquoi.
///
/// Volontairement sans action : la condition qui la retient — une inscription
/// pas encore synchronisée, le plus souvent — ne se lève pas depuis cette
/// liste. Offrir un « Réessayer » ici produirait un nouveau report immédiat,
/// et le geste serait un mensonge.
///
/// Pas d'icône d'erreur, pas de rouge : une retenue n'est pas un échec.
/// L'écriture est conservée, ses tentatives intactes, elle partira seule.
class SyncHeldTile extends StatelessWidget {
  final OutboxEntry entry;

  const SyncHeldTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final queuedAt = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  [
                    syncAggregateLabel(l10n, entry.aggregateType),
                    ?syncAggregateBusinessKey(
                      entry.aggregateType,
                      entry.aggregateId,
                    ),
                  ].join(' · '),
                  style: AppTypography.titleSmall,
                ),
              ),
              Text(
                l10n.syncErrorsQueuedAt(queuedAt, queuedAt),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (entry.lastError != null && entry.lastError!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            // Motif brut, comme pour une erreur : c'est un diagnostic destiné à
            // être lu au guichet, pas un message à reformuler.
            Text(
              entry.lastError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
