import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_cycle_card.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_totals_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 3 — cycles, niveaux et classes.
///
/// **Tout est proposé par défaut** : le promoteur retire ce qu'il n'offre pas
/// plutôt que de tout construire. Mais rien de ce qui s'affiche n'est écrit dans
/// l'application — l'écran est le rendu d'un catalogue servi.
class StructureStep extends StatelessWidget {
  const StructureStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ConfigurationBloc, ConfigurationState>(
      buildWhen: (previous, current) =>
          previous.draft.cycles != current.draft.cycles ||
          previous.catalog != current.catalog ||
          previous.plan != current.plan ||
          previous.status != current.status,
      builder: (context, state) {
        final catalog = state.catalog;
        if (catalog == null) return const SizedBox.shrink();

        final bloc = context.read<ConfigurationBloc>();
        final selection = StructureSelection.fromDraft(state.draft, catalog);

        void apply(StructureSelection next) {
          bloc.add(
            ConfigurationDraftChanged(
              state.draft.copyWith(cycles: next.toCycles(catalog)),
            ),
          );
        }

        // L'état vide se déclenche sur la sélection locale et non sur
        // `plan.counts` : le plan met une temporisation à revenir, et l'écran
        // basculerait en « aucun niveau retenu » un instant après chaque
        // décochage, y compris quand il en reste.
        final empty = selection.counts.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConfigurationTotalsBar(
              counts: state.counts,
              // Masqué pendant le chargement et l'erreur : mieux vaut aucun
              // chiffre qu'un chiffre faux.
              visible: !state.isLoading && !state.hasFailure,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (empty)
              EteeloEmptyResult(
                medallionIcon: Icons.layers_clear_rounded,
                accentColor: AppColors.terreCuite,
                label: l10n.configurationStructureEmptyTitle,
                description: l10n.configurationStructureEmptyMessage,
                primaryAction: FilledButton.icon(
                  onPressed: () =>
                      apply(StructureSelection.defaultFor(catalog)),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l10n.configurationStructureRestore),
                ),
              )
            else
              for (final cycle in catalog.cycles)
                ConfigurationCycleCard(
                  cycle: cycle,
                  selection: selection,
                  onChanged: apply,
                ),
          ],
        );
      },
    );
  }
}
