import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelettes de chargement de l'assistant — **jamais un spinner** (règle
/// projet).
///
/// Chacun conserve la mise en page de son étape : la page ne saute pas quand les
/// données arrivent, et l'agent sait déjà où regarder.
///
/// Seul le CORPS est squeletté. La barre de titre, le rail et le titre d'étape
/// restent réels : ils ne dépendent d'aucune donnée, et les faire clignoter
/// donnerait l'impression que tout l'écran se recharge.
class ConfigurationStepSkeleton extends StatelessWidget {
  final ConfigurationStep step;

  const ConfigurationStepSkeleton({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      // L'attente est annoncée, pas seulement dessinée — et sur les CINQ
      // étapes. Portée par une seule enveloppe : la poser sur chaque squelette
      // ferait dépendre l'annonce de la forme de l'étape, et l'étape 3 en
      // aurait trois d'un coup.
      liveRegion: true,
      label: l10n.configurationLoadingA11yLabel,
      child: ExcludeSemantics(
        // Les blocs ne disent rien un par un : sans cette exclusion, le lecteur
        // d'écran parcourrait une vingtaine de rectangles muets pour trouver la
        // seule phrase qui compte.
        child: switch (step) {
          // Étapes 1 et 2 : des grilles de champs.
          ConfigurationStep.school => const _FormSkeleton(rows: 4, columns: 2),
          ConfigurationStep.academicYear => const _FormSkeleton(
            rows: 2,
            columns: 2,
          ),
          ConfigurationStep.structure => const _StructureSkeleton(),
          ConfigurationStep.fees => const _RowsSkeleton(rows: 3),
          ConfigurationStep.activation => const _RowsSkeleton(rows: 4),
        },
      ),
    );
  }
}

class _FormSkeleton extends StatelessWidget {
  final int rows;
  final int columns;

  const _FormSkeleton({required this.rows, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Row(
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EteeloSkeletonBox(width: 90, height: 10),
                        SizedBox(height: AppSpacing.xs),
                        EteeloSkeletonBox(width: double.infinity, height: 46),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _StructureSkeleton extends StatelessWidget {
  const _StructureSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le bandeau de totaux ne se squelette PAS : il est masqué pendant le
        // chargement. Un chiffre en attente se lit comme un chiffre.
        for (var card = 0; card < 3; card++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EteeloSkeletonBox(width: 180, height: 16),
                SizedBox(height: AppSpacing.sm),
                EteeloSkeletonBox(width: double.infinity, height: 48),
                SizedBox(height: AppSpacing.xs),
                EteeloSkeletonBox(width: double.infinity, height: 48),
              ],
            ),
          ),
      ],
    );
  }
}

class _RowsSkeleton extends StatelessWidget {
  final int rows;

  const _RowsSkeleton({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < rows; row++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: EteeloSkeletonBox(width: double.infinity, height: 64),
          ),
      ],
    );
  }
}
