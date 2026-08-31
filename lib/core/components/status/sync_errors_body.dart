import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/outbox_retry_policy.dart';
import 'package:school_app_flutter/core/components/status/sync_error_tile.dart';
import 'package:school_app_flutter/core/components/status/sync_held_tile.dart';
import 'package:school_app_flutter/core/components/status/sync_other_account_band.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rend défilant un état qui ne sait pas se réduire.
///
/// Le corps de la feuille vit dans un `Expanded` : sa hauteur est ce qui RESTE
/// une fois l'en-tête et le bandeau posés. Or les trois états non-listes ont
/// une hauteur PLANCHER que rien ne négocie — 212 px pour le squelette, 380 px
/// pour les deux cartes partagées. Sur un écran court, l'apparition du bandeau
/// « lecture incomplète » suffit à faire passer l'espace restant sous ce
/// plancher, et le rendu déborde : c'est le seul état de la pastille qui monte
/// ce bandeau, donc le seul où le débordement se voyait.
///
/// `minHeight` recopie la contrainte serrée que l'`Expanded` donnait : quand la
/// place est là, la carte occupe toujours toute la zone et rien ne bouge.
Widget _fitOrScroll(Widget child) => LayoutBuilder(
  builder: (context, constraints) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: child,
    ),
  ),
);

/// Le corps de la feuille de reprise ([showSyncErrorsSheet]) : ce que l'outbox
/// a à montrer, et rien d'autre.
///
/// Séparé de la feuille parce qu'il ne connaît QUE l'outbox. Ce qui relève de
/// la lecture (le bandeau « lecture incomplète », l'en-tête qui suit la porte
/// d'entrée) vit au-dessus de lui, dans la feuille : posé ici, il serait avalé
/// par l'état vide — c'est le cas le plus courant d'une lecture incomplète, et
/// l'utilisateur lirait le contraire de ce qu'on veut lui dire.
class SyncErrorsBody extends StatelessWidget {
  const SyncErrorsBody({super.key});

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
          return _fitOrScroll(
            const EteeloListSkeleton(rowCount: 3, showAvatar: false),
          );
        }
        if (state.status == OutboxErrorsStatus.failure) {
          return _fitOrScroll(
            EteeloErrorResult(
              // Lecture d'une base locale : ni réseau, ni droits — `unknown`
              // est le seul type honnête ici, et il ne propose pas de
              // « Réessayer » trompeur sur une base indisponible.
              type: EteeloErrorType.unknown,
              title: l10n.syncErrorsLoadFailedTitle,
              message: l10n.syncErrorsLoadFailedMessage,
            ),
          );
        }
        if (state.isEmpty) {
          return _fitOrScroll(
            EteeloEmptyResult(
              label: l10n.syncErrorsEmptyLabel,
              description: l10n.syncErrorsEmptyDescription,
              medallionIcon: Icons.cloud_done_outlined,
            ),
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
