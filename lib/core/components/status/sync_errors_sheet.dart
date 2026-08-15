import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/outbox_retry_policy.dart';
import 'package:school_app_flutter/core/components/status/sync_error_tile.dart';
import 'package:school_app_flutter/core/components/status/sync_held_tile.dart';
import 'package:school_app_flutter/core/components/status/sync_incomplete_read_band.dart';
import 'package:school_app_flutter/core/components/status/sync_other_account_band.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la feuille de reprise des écritures en échec.
///
/// À la fermeture, rafraîchit la pastille globale : un requeue réussi doit faire
/// retomber « Conflit » sans attendre un autre événement.
Future<void> showSyncErrorsSheet(BuildContext context) async {
  final syncStatusCubit = context.read<SyncStatusCubit>();
  // Relevé MAINTENANT, sur le contexte de l'appelant. La feuille est montée
  // dans le sous-arbre du `Navigator`, où l'on n'a pas à parier sur la
  // visibilité des providers de la racine — et la valeur ne peut de toute
  // façon pas changer utilement le temps d'une modale ouverte.
  final hasIncompleteRead = syncStatusCubit.state.hasIncompleteRead;
  final hasRetriableRead = syncStatusCubit.state.hasRetriableRead;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.card),
    ),
    builder: (sheetContext) => BlocProvider<OutboxErrorsCubit>(
      create: (_) => getIt<OutboxErrorsCubit>()..load(),
      child: _SyncErrorsSheet(
        hasIncompleteRead: hasIncompleteRead,
        retriable: hasRetriableRead,
        // Ferme la feuille PUIS relance : le cycle dure, et le laisser tourner
        // derrière une modale ouverte n'y afficherait rien de plus. La pastille
        // passe à « Synchro… », et le `refresh()` de fermeture ci-dessous
        // recalcule l'état — même chemin qu'un requeue d'écriture.
        onRetry: () {
          Navigator.of(sheetContext).pop();
          unawaited(syncStatusCubit.syncNow());
        },
      ),
    ),
  );
  await syncStatusCubit.refresh();
}

class _SyncErrorsSheet extends StatelessWidget {
  /// Le dernier cycle de lecture n'a pas tout ramené (ADR-015 F1).
  final bool hasIncompleteRead;

  /// …et au moins une cause est un échec de transport, donc rattrapable.
  final bool retriable;

  final VoidCallback onRetry;

  const _SyncErrorsSheet({
    required this.hasIncompleteRead,
    required this.retriable,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  // L'en-tête suit la porte par laquelle on est entré. Ouverte
                  // sur une lecture incomplète, la feuille n'a le plus souvent
                  // AUCUNE écriture à montrer — annoncer « Écritures en échec »
                  // et « refusés par le serveur » y serait faux deux fois, et
                  // du même genre de faux que ce lot corrige ailleurs.
                  child: Text(
                    hasIncompleteRead
                        ? l10n.syncSheetStatusTitle
                        : l10n.syncErrorsTitle,
                    style: AppTypography.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.syncErrorsClose,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasIncompleteRead
                  ? l10n.syncSheetStatusSubtitle
                  : l10n.syncErrorsSubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // AU-DESSUS du corps, et pas dedans : le corps ne connaît que
            // l'outbox et affiche « Aucune écriture en échec » dès qu'elle est
            // vide — c'est-à-dire dans le cas le plus courant d'une lecture
            // incomplète.
            if (hasIncompleteRead)
              SyncIncompleteReadBand(retriable: retriable, onRetry: onRetry),
            const Expanded(child: _SyncErrorsBody()),
          ],
        ),
      ),
    );
  }
}

class _SyncErrorsBody extends StatelessWidget {
  const _SyncErrorsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OutboxErrorsCubit, OutboxErrorsState>(
      builder: (context, state) {
        final me = getIt<CurrentUserContext>().uid;
        final otherName = state.otherAuthors.length == 1
            ? SyncOtherAccountBand.shortNameOf(state.otherAuthors.first)
            : null;
        if (state.status == OutboxErrorsStatus.loading) {
          return const EteeloListSkeleton(rowCount: 3, showAvatar: false);
        }
        if (state.status == OutboxErrorsStatus.failure) {
          return EteeloErrorResult(
            // Lecture d'une base locale : ni réseau, ni droits — `unknown` est
            // le seul type honnête ici, et il ne propose pas de « Réessayer »
            // trompeur sur une base indisponible.
            type: EteeloErrorType.unknown,
            title: l10n.syncErrorsLoadFailedTitle,
            message: l10n.syncErrorsLoadFailedMessage,
          );
        }
        if (state.isEmpty) {
          return EteeloEmptyResult(
            label: l10n.syncErrorsEmptyLabel,
            description: l10n.syncErrorsEmptyDescription,
            medallionIcon: Icons.cloud_done_outlined,
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  final foreign = isForeignOutboxAuthor(entry.payload, me);
                  return SyncErrorTile(
                    entry: entry,
                    busy: state.busy,
                    canRetry: canRetryEntry(
                      aggregateType: entry.aggregateType,
                      payload: entry.payload,
                      currentUid: me,
                    ),
                    isForeign: foreign,
                    foreignAuthorName: foreign ? otherName : null,
                    onRetry: () =>
                        context.read<OutboxErrorsCubit>().retry(entry.id),
                  );
                },
              ),
            ),
            // MES écritures retenues, avec leur motif. Sans cette section, un
            // paiement qui attend l'inscription de son élève n'existe nulle
            // part à l'écran : ni erreur (il n'en est pas une), ni bande
            // « autre compte » (il est à moi) — juste un « à envoyer » muet.
            if (state.held.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.syncErrorsHeldTitle, style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.syncErrorsHeldSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...state.held.map((e) => SyncHeldTile(entry: e)),
            ],
            // Explication de l'attente d'un autre compte, sous la liste : ce
            // n'est pas une erreur de l'utilisateur courant, ça ne doit pas
            // passer devant ses propres écritures à reprendre.
            if (!state.others.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SyncOtherAccountBand(
                others: state.others,
                authors: state.otherAuthors,
              ),
            ],
            // « Tout réessayer » n'apparaît que s'il y a effectivement quelque
            // chose à rejouer PAR MOI : le prédicat porte sur `canRetryEntry`,
            // pas sur le seul type — sinon une liste entièrement composée
            // d'écritures d'un autre compte afficherait un bouton actif dont le
            // clic ne fait strictement rien.
            if (state.entries.any(
              (e) => canRetryEntry(
                aggregateType: e.aggregateType,
                payload: e.payload,
                currentUid: me,
              ),
            )) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.busy
                      ? null
                      : () => context.read<OutboxErrorsCubit>().retryAll(),
                  child: Text(l10n.syncErrorsRetryAll),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
