import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord en train de se charger — **à sa propre silhouette**.
///
/// Un `CircularProgressIndicator` centré ne dit rien de ce qui arrive : l'écran
/// saute d'un rond qui tourne à une grille dense, et la page se réagence sous
/// l'œil. Les blocs ci-dessous occupent les mêmes places que la bande KPI et
/// les deux cartes qui vont les remplacer.
///
/// Le mouvement réduit est respecté par [EteeloSkeletonBox] lui-même.
class FinanceStatsLoadingView extends StatelessWidget {
  /// Nombre de cartes de la bande. Trois pour la caisse — total, frais,
  /// boutique — quatre pour le recouvrement, qui compte en plus le taux.
  final int kpiCount;

  const FinanceStatsLoadingView({super.key, this.kpiCount = 4});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.financeStatsLoadingA11yLabel,
      readOnly: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= AppBreakpoints.financeStatsTwoColMin;
            final cardWidth =
                (constraints.maxWidth -
                    AppDimensions.spacingM * (kpiCount - 1)) /
                kpiCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimensions.spacingM,
                  runSpacing: AppDimensions.spacingM,
                  children: [
                    for (var i = 0; i < kpiCount; i++)
                      EteeloSkeletonBox(
                        width: cardWidth.clamp(140.0, double.infinity),
                        height: AppDimensions.spacingXL * 3,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.spacingM,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingL),
                if (wide)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _SectionSkeleton()),
                      SizedBox(width: AppDimensions.spacingL),
                      Expanded(flex: 3, child: _SectionSkeleton()),
                    ],
                  )
                else
                  const Column(
                    children: [
                      _SectionSkeleton(),
                      SizedBox(height: AppDimensions.spacingL),
                      _SectionSkeleton(),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// L'emplacement d'une carte de section : son titre, puis son tracé.
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EteeloSkeletonBox(
          width: 180,
          height: AppDimensions.spacingM,
          borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        EteeloSkeletonBox(
          height: AppDimensions.spacingXL * 6,
          borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        ),
      ],
    );
  }
}
