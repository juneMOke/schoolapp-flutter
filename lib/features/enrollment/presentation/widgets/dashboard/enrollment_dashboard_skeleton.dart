import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord en train de se charger — **à sa propre silhouette**.
///
/// Un `CircularProgressIndicator` centré ne dit rien de ce qui arrive : l'écran
/// saute d'un rond qui tourne à une grille dense, et la page se réagence sous
/// l'œil. Les blocs ci-dessous occupent les mêmes places, aux mêmes seuils de
/// rupture, que ceux qui vont les remplacer : bande de quatre cartes, carte de
/// rythme, paire « qui », classements « où ».
///
/// C'est aussi la règle non négociable n°10 du dépôt : aucune zone de résultats
/// ne monte son propre indicateur ; le chargement passe par les squelettes
/// partagés, qui respectent seuls `prefers-reduced-motion`.
class EnrollmentDashboardSkeleton extends StatelessWidget {
  /// Nombre de cartes de la bande d'indicateurs.
  final int kpiCount;

  const EnrollmentDashboardSkeleton({super.key, this.kpiCount = 4});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Une seule annonce pour tout le chargement : `liveRegion` sur l'ensemble,
    // et le contenu visuel masqué au lecteur d'écran. Une annonce par bloc se
    // lirait comme cinq chargements successifs.
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.enrollmentDashboardLoadingA11yLabel,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns =
                constraints.maxWidth >=
                AppBreakpoints.attendanceOverviewTwoColMin;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EteeloKpiBandSkeleton(count: kpiCount),
                const SizedBox(height: AppDimensions.spacingL),
                // Le rythme.
                const EteeloChartSkeleton(),
                const SizedBox(height: AppDimensions.spacingL),
                // La paire « qui » — même seuil de rupture que la vue chargée.
                if (twoColumns)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: EteeloBarRowsSkeleton(rows: 2)),
                      SizedBox(width: AppDimensions.spacingL),
                      Expanded(child: EteeloBarRowsSkeleton(rows: 2)),
                    ],
                  )
                else
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EteeloBarRowsSkeleton(rows: 2),
                      SizedBox(height: AppDimensions.spacingL),
                      EteeloBarRowsSkeleton(rows: 2),
                    ],
                  ),
                const SizedBox(height: AppDimensions.spacingL),
                // « Où » : le classement par niveau, puis par cycle.
                const EteeloBarRowsSkeleton(rows: 5),
                const SizedBox(height: AppDimensions.spacingL),
                const EteeloBarRowsSkeleton(rows: 3),
              ],
            );
          },
        ),
      ),
    );
  }
}
