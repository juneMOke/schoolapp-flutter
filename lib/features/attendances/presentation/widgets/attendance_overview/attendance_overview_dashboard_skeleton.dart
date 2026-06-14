import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Hauteur d'un panneau fantome — approxime une carte de section chargee
/// (chrome titre + padding ~84 + zone graphique 220).
const double _kGhostPanelHeight = 300.0;

/// Ombre douce commune aux cartes (alignee sur EteeloKpiCard / AttendanceOverviewCard).
List<BoxShadow> get _cardShadow => [
  BoxShadow(
    color: AppColors.textPrimary.withValues(alpha: 0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

/// Squelette de chargement du tableau de bord des presences. Reproduit la MEME
/// grille responsive que la vue chargee (cartes KPI qui s'enroulent en
/// 4 / 2×2 / 1 via [EteeloKpiBand.columnsFor], paires de panneaux qui s'empilent
/// aux memes seuils, memes hauteurs/ombres/arrondis) afin d'eviter tout saut de
/// mise en page a l'arrivee des donnees.
///
/// `liveRegion` + `container` via Semantics pour annoncer le chargement ; le
/// contenu visuel est masque par [ExcludeSemantics]. Le pouls respecte
/// reduced-motion (delegue a [EteeloSkeletonBox]).
class AttendanceOverviewDashboardSkeleton extends StatelessWidget {
  const AttendanceOverviewDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.attendanceOverviewLoadingA11yLabel,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Mêmes seuils que la vue chargée : paire Évolution/Motifs (large)
            // et paire Jour/Top (standard).
            final wideRow =
                constraints.maxWidth >=
                AppBreakpoints.attendanceOverviewWideTwoColMin;
            final standardRow =
                constraints.maxWidth >=
                AppBreakpoints.attendanceOverviewTwoColMin;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GhostKpiBand(maxWidth: constraints.maxWidth),
                const SizedBox(height: AppDimensions.spacingL),
                const EteeloSkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                const SizedBox(height: AppDimensions.spacingL),
                _GhostPair(twoCol: wideRow, startFlex: 2, endFlex: 1),
                const SizedBox(height: AppDimensions.spacingL),
                _GhostPair(twoCol: standardRow, startFlex: 1, endFlex: 1),
                const SizedBox(height: AppDimensions.spacingL),
                const _GhostTable(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bande KPI fantome : enroulement identique a [EteeloKpiBand]
/// (cascade 4 / 2×2 / 1 via le meme calcul de colonnes).
class _GhostKpiBand extends StatelessWidget {
  final double maxWidth;

  const _GhostKpiBand({required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    const gap = AppDimensions.spacingM;
    final columns = EteeloKpiBand.columnsFor(maxWidth, 4);
    final cardWidth = ((maxWidth - gap * (columns - 1)) / columns)
        .floorToDouble();

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (var i = 0; i < 4; i++)
          SizedBox(width: cardWidth, child: const _GhostKpiCard()),
      ],
    );
  }
}

/// Paire de panneaux fantomes : cote a cote (flex) en large, empiles en etroit.
class _GhostPair extends StatelessWidget {
  final bool twoCol;
  final int startFlex;
  final int endFlex;

  const _GhostPair({
    required this.twoCol,
    required this.startFlex,
    required this.endFlex,
  });

  @override
  Widget build(BuildContext context) {
    if (!twoCol) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GhostPanel(),
          SizedBox(height: AppDimensions.spacingL),
          _GhostPanel(),
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: startFlex, child: const _GhostPanel()),
        const SizedBox(width: AppDimensions.spacingL),
        Expanded(flex: endFlex, child: const _GhostPanel()),
      ],
    );
  }
}

/// Carte KPI fantome : iso-carte chargee (hauteur, arrondi, ombre, lisere
/// gauche neutre rappelant l'accent colore).
class _GhostKpiCard extends StatelessWidget {
  const _GhostKpiCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.kpiCardHeightWithSubline,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentStatsChartRadius,
        ),
        border: const Border(
          left: BorderSide(color: AppColors.border, width: 3),
        ),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EteeloSkeletonBox(
            width: 26,
            height: 26,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          SizedBox(height: AppDimensions.spacingS),
          EteeloSkeletonBox(width: 64, height: 18),
          SizedBox(height: AppDimensions.spacingXS),
          EteeloSkeletonBox(width: 88, height: 9),
        ],
      ),
    );
  }
}

/// Panneau fantome : carte surelevee bordee (iso-AttendanceOverviewCard) avec
/// un titre simule et une grande zone (graphique/contenu) simulee.
class _GhostPanel extends StatelessWidget {
  const _GhostPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kGhostPanelHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EteeloSkeletonBox(width: 140, height: 14),
          SizedBox(height: AppDimensions.spacingM),
          Expanded(
            child: EteeloSkeletonBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimensions.spacingS),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tableau fantome (par classe) : carte surelevee bordee, entete + 6 lignes.
class _GhostTable extends StatelessWidget {
  const _GhostTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EteeloSkeletonBox(width: 160, height: 14),
          const SizedBox(height: AppDimensions.spacingM),
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(height: AppDimensions.spacingS),
            const EteeloSkeletonBox(width: double.infinity, height: 12),
          ],
        ],
      ),
    );
  }
}
