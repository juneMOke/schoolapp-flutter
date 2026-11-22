import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_figure_pave.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_figures_support.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_situation_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc B · les chiffres de tête (spec §4.6 B, R5, D3-D5).
///
/// Trois pavés — « Attendu », « Perçu à ce jour », « Reste à percevoir » —
/// puis la carte « Situation des {n} élèves ». Tout vient de la réponse du
/// serveur : rien n'est recalculé ici, sauf les sous-lignes qui comptent des
/// élèves déjà comptés.
///
/// **Mixte** : chaque pavé porte un montant par devise, dollars puis francs,
/// jamais additionnés ; l'anneau du taux disparaît (un taux toutes devises
/// confondues n'existe pas).
///
/// **Bande fluide** (`minmax(230px, 1fr)` de la maquette) : une carte par
/// ligne au téléphone, 2 × 2 de 552 à 708 reçus, 3 + 1 à 828, quatre en ligne
/// dès 1112. Les cartes d'une même rangée prennent la hauteur de la plus haute.
///
/// ⚠️ Écart assumé à `EteeloKpiBand` : sa cascade évite le 3 + 1 voulu ici à
/// 828, et sa quatrième carte ne peut pas être la carte Situation. La grille
/// reprend son espacement ([AppDimensions.spacingM]) et sa règle d'auto-fill.
class RecoveryKeyFiguresSection extends StatelessWidget {
  final RecoveryDashboard dashboard;
  final ValueChanged<StudentChargeStatus> onSituationTapped;

  const RecoveryKeyFiguresSection({
    super.key,
    required this.dashboard,
    required this.onSituationTapped,
  });

  /// Colonnes pour [width] reçus : auto-fill sur une carte de 230 dp au moins.
  static int columnsFor(double width, {int count = 4}) {
    const gap = AppDimensions.spacingM;
    const min = AppDimensions.recoveryKeyFigureMinWidth;
    return ((width + gap) / (min + gap)).floor().clamp(1, count);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = _cards(l10n);

    return Semantics(
      container: true,
      label: l10n.recoveryFiguresA11yLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppDimensions.spacingM;
          final columns = columnsFor(constraints.maxWidth, count: cards.length);
          final width = ((constraints.maxWidth - gap * (columns - 1)) / columns)
              .floorToDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var start = 0; start < cards.length; start += columns) ...[
                if (start > 0) const SizedBox(height: gap),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var i = start;
                        i < cards.length && i < start + columns;
                        i++
                      ) ...[
                        if (i > start) const SizedBox(width: gap),
                        SizedBox(width: width, child: cards[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _cards(AppLocalizations l10n) {
    final figures = RecoveryFiguresSupport.orderedFigures(dashboard);
    final single = figures.length == 1 ? figures.single : null;
    final dash = l10n.recouvrementNoAmountDash;
    final situations = dashboard.situations;
    // Le taux perçu n'existe que dans une devise, et seulement s'il y a un dû.
    final rate = single?.ratePercent;

    return [
      RecoveryFigurePave(
        key: const ValueKey('recovery-figure-expected'),
        label: l10n.recoveryFiguresExpected,
        icon: Icons.assignment_outlined,
        accent: DashboardSense.attendu,
        values: RecoveryFiguresSupport.amountLines(
          figures,
          (f) => f.dueInCents,
          dash,
        ),
        subline: single != null
            ? l10n.recoveryFiguresExpectedSubline(single.currency)
            : l10n.recoveryFiguresExpectedMixedSubline,
      ),
      RecoveryFigurePave(
        key: const ValueKey('recovery-figure-collected'),
        label: l10n.recoveryFiguresCollected,
        icon: Icons.payments_outlined,
        accent: DashboardSense.encaisse,
        values: RecoveryFiguresSupport.amountLines(
          figures,
          (f) => f.paidInCents,
          dash,
        ),
        subline: l10n.recoveryFiguresSettledSubline(situations.settled),
        ringPercent: rate,
        ringLabel: rate == null ? null : l10n.recoveryFiguresRateRing(rate),
        ringSemantics: rate == null
            ? null
            : l10n.recoveryFiguresRateRingA11y(rate),
      ),
      RecoveryFigurePave(
        key: const ValueKey('recovery-figure-remaining'),
        label: l10n.recoveryFiguresRemaining,
        icon: Icons.schedule_outlined,
        accent: DashboardSense.marque,
        values: RecoveryFiguresSupport.amountLines(
          figures,
          (f) => f.outstandingInCents,
          dash,
        ),
        subline: l10n.recoveryFiguresRemainingSubline(
          situations.noPayment + situations.partial,
        ),
      ),
      RecoverySituationCard(
        key: const ValueKey('recovery-figure-situation'),
        counts: situations,
        studentCount: dashboard.studentCount,
        onSituationTapped: onSituationTapped,
      ),
    ];
  }
}
