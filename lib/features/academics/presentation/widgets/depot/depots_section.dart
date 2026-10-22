import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/depot/depots_cubit.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/depot/depots_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/depot_actions.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/depot/depot_eleve_row.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval_detail/eval_section_card.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/states/eval_saisie_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les copies déposées par les parents pour un devoir en ligne : la classe,
/// qui a rendu (à l'heure ou en retard), qui pas encore, et chaque copie à
/// ouvrir. Corriger reste la saisie des notes habituelle.
class DepotsSection extends StatelessWidget {
  final String evaluationId;

  const DepotsSection({super.key, required this.evaluationId});

  @override
  Widget build(BuildContext context) => BlocProvider<DepotsCubit>(
    create: (_) => getIt<DepotsCubit>()..start(evaluationId),
    child: const _DepotsCard(),
  );
}

class _DepotsCard extends StatelessWidget {
  const _DepotsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<DepotsCubit, DepotsState>(
      builder: (context, state) {
        final copies = state.copies;
        return EvalSectionCard(
          title: l10n.depotsSectionTitle,
          subtitle: state.load == DepotsLoad.ready
              ? l10n.depotsCompteur(copies.rendues, copies.total)
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: switch (state.load) {
              DepotsLoad.loading => const EteeloListSkeleton(rowCount: 3),
              DepotsLoad.failure => EvalSaisieResultsErrorState.failure(
                failure: state.failure!,
                onRetry: () => unawaited(context.read<DepotsCubit>().refresh()),
              ),
              DepotsLoad.ready => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final eleve in copies.eleves)
                    DepotEleveRow(
                      key: ValueKey(eleve.studentId),
                      eleve: eleve,
                      canOpen: state.canOpen(eleve),
                      onOpen: () => unawaited(openDepotCopie(context, eleve)),
                    ),
                ],
              ),
            },
          ),
        );
      },
    );
  }
}
