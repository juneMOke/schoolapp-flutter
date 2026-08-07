import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/outbox_retry_policy.dart';
import 'package:school_app_flutter/core/components/status/sync_aggregate_labels.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une écriture en échec : ce qui a été refusé, quand, et pourquoi.
///
/// Le motif serveur (`lastError`) est affiché **brut** : c'est un diagnostic
/// destiné à être lu au guichet ou recopié au support, pas un message d'UI à
/// reformuler — le traduire ferait perdre l'information utile.
class SyncErrorTile extends StatelessWidget {
  /// Nom court de l'auteur quand l'entrée appartient à un AUTRE compte
  /// (`null` = elle est à moi, ou l'auteur est inconnu).
  final String? foreignAuthorName;

  final OutboxEntry entry;
  final bool busy;
  final VoidCallback onRetry;

  /// Vrai si le porteur courant peut réellement rejouer cette entrée
  /// ([canRetryEntry]). Faux → aucun bouton, une explication à la place.
  final bool canRetry;

  /// Vrai si l'entrée appartient à un autre compte — départage les deux motifs
  /// de refus du rejeu.
  final bool isForeign;

  const SyncErrorTile({
    super.key,
    required this.entry,
    required this.busy,
    required this.onRetry,
    required this.canRetry,
    required this.isForeign,
    this.foreignAuthorName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final queuedAt = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
    final when = l10n.syncErrorsQueuedAt(queuedAt, queuedAt);

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
                Icons.error_outline_rounded,
                size: 18,
                color: AppColors.error,
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
                when,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (entry.lastError != null && entry.lastError!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              entry.lastError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (!canRetry)
            // Deux raisons de ne pas offrir le bouton, deux messages :
            //  - payload gelé non rejouable (présence : republier effacerait
            //    côté serveur les absences ajoutées depuis) ;
            //  - écriture d'un AUTRE compte : le serveur la refuserait, et le
            //    rejeu la ferait seulement disparaître de cette liste.
            Text(
              isForeign
                  ? (foreignAuthorName == null
                        ? l10n.syncErrorsForeignEntryAnonymous
                        : l10n.syncErrorsForeignEntry(foreignAuthorName!))
                  : l10n.syncErrorsNotReplayable,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  // Largeur bornée : sans `minimumSize`, le thème plein-largeur
                  // fait exploser un bouton inline dans une Row.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                  ),
                  onPressed: busy ? null : onRetry,
                  child: Text(l10n.syncErrorsRetry),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
