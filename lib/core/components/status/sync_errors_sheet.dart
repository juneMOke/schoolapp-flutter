import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_errors_body.dart';
import 'package:school_app_flutter/core/components/status/sync_incomplete_read_band.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la feuille de reprise des écritures en échec.
///
/// À la fermeture, rafraîchit la pastille globale : un requeue réussi doit faire
/// retomber « Conflit » sans attendre un autre événement.
Future<void> showSyncErrorsSheet(BuildContext context) async {
  // Le cubit est relevé MAINTENANT, sur le contexte de l'appelant : la feuille
  // est montée dans le sous-arbre du `Navigator`, où l'on n'a pas à parier sur
  // la visibilité des providers de la racine. C'est l'INSTANCE qu'on emporte,
  // pas une photo de son état.
  //
  // ⚠️ La photo était justifiée par « la valeur ne peut de toute façon pas
  // changer utilement le temps d'une modale ouverte ». Le battement de la file
  // a périmé cette prémisse : un tic de 45 s tombe pendant qu'on lit. Il peut
  // lever la dégradation sous les yeux de l'utilisateur — « Réessayer » brûle
  // alors un cycle de dix-neuf ressources pour rien — ou l'introduire alors que
  // la feuille n'offre plus ni bandeau ni geste.
  final syncStatusCubit = context.read<SyncStatusCubit>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.card),
    ),
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        // `.value` : la racine reste propriétaire du cubit, la feuille ne le
        // ferme pas en se refermant.
        BlocProvider<SyncStatusCubit>.value(value: syncStatusCubit),
        BlocProvider<OutboxErrorsCubit>(
          create: (_) => getIt<OutboxErrorsCubit>()..load(),
        ),
      ],
      child: _SyncErrorsSheet(
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
  final VoidCallback onRetry;

  const _SyncErrorsSheet({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Abonné, plus photographié : le titre, le sous-titre et le bandeau suivent
    // le cycle en cours. `buildWhen` borne la reconstruction aux deux champs
    // lus — un tic qui ne change que l'horodatage de dernière synchro ne doit
    // pas repeindre la feuille sous les doigts de l'utilisateur.
    return BlocBuilder<SyncStatusCubit, SyncStatusState>(
      buildWhen: (previous, current) =>
          previous.hasIncompleteRead != current.hasIncompleteRead ||
          previous.hasRetriableRead != current.hasRetriableRead,
      builder: (context, status) => _buildSheet(
        context,
        status.hasIncompleteRead,
        status.hasRetriableRead,
      ),
    );
  }

  Widget _buildSheet(
    BuildContext context,
    bool hasIncompleteRead,
    bool retriable,
  ) {
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
            const Expanded(child: SyncErrorsBody()),
          ],
        ),
      ),
    );
  }
}
