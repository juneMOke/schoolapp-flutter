import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/outbox_retry_policy.dart';
import 'package:school_app_flutter/core/components/status/sync_error_tile.dart';
import 'package:school_app_flutter/core/components/status/sync_held_tile.dart';
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
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.card),
    ),
    builder: (_) => BlocProvider<OutboxErrorsCubit>(
      create: (_) => getIt<OutboxErrorsCubit>()..load(),
      child: const _SyncErrorsSheet(),
    ),
  );
  await syncStatusCubit.refresh();
}

class _SyncErrorsSheet extends StatelessWidget {
  const _SyncErrorsSheet();

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
                  child: Text(
                    l10n.syncErrorsTitle,
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
              l10n.syncErrorsSubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
