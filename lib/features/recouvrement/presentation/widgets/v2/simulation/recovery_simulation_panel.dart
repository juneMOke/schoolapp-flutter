import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_cards.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_controls.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_figures.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_table.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_texts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Qui la simulation vise, pour la question posée : « N'ont rien payé » ·
/// « N'ont pas tout soldé » · « Ont payé moins que {montant} ». « Au moins »
/// sans montant retombe sur « a payé quelque chose » ([RecoveryQuestion.
/// effectiveRule]). [currency] — l'unique devise du périmètre — écrit le
/// montant avec son symbole ; sans elle, le montant seul.
String recoveryCriterionLabel(
  RecoveryQuestion question,
  AppLocalizations l10n, {
  String? currency,
}) => recoveryTargetedLabel(
  question.effectiveRule,
  question.thresholdInCents,
  currency,
  l10n,
);

/// F · « Simulation : si on renvoyait les élèves pas en ordre » (R12, D10).
///
/// **Rien n'est appliqué** : ni bouton « Appliquer », ni action de masse. Le
/// critère est celui de E (A11) ; seul le seuil « ingérable » se règle ici.
/// Les chiffres viennent tous du serveur, dans son ordre (les plus touchées
/// d'abord) ; seuls les verdicts dépendent du seuil, calculés à l'écran.
class RecoverySimulationPanel extends StatelessWidget {
  final RecoveryDashboard dashboard;
  final RecoveryRuleKind rule;
  final int? thresholdInCents;
  final int unmanageableBelow;
  final ValueChanged<int> onUnmanageableChanged;
  final VoidCallback onChangeRule;

  /// N'est appelé que pour une classe dont des élèves sont visés (I16).
  final ValueChanged<RecoverySimulationRow> onClassTapped;

  const RecoverySimulationPanel({
    super.key,
    required this.dashboard,
    required this.rule,
    required this.thresholdInCents,
    required this.unmanageableBelow,
    required this.onUnmanageableChanged,
    required this.onChangeRule,
    required this.onClassTapped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final simulation = dashboard.simulation;
    final rows = recoverySimulationOrdered(simulation);
    // La bascule se mesure sur la largeur REÇUE par le bloc (§4.1), pas sur
    // l'intérieur de la carte : à 600 reçus, le tableau.
    return LayoutBuilder(
      builder: (context, constraints) => _card(
        l10n,
        simulation,
        rows,
        narrow: constraints.maxWidth < AppBreakpoints.dataTableCardsMax,
      ),
    );
  }

  Widget _card(
    AppLocalizations l10n,
    RecoverySimulation simulation,
    List<RecoverySimulationRow> rows, {
    required bool narrow,
  }) {
    return EteeloStatsCard(
      title: l10n.recoverySimulationTitle,
      subtitle: l10n.recoverySimulationSubtitle,
      icon: Icons.person_remove_outlined,
      iconColor: AppColors.terreCuite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecoverySimulationControls(
            criterionLabel: recoveryTargetedLabel(
              rule,
              thresholdInCents,
              recoverySoleCurrency(dashboard),
              l10n,
            ),
            unmanageableBelow: unmanageableBelow,
            onUnmanageableChanged: onUnmanageableChanged,
            onChangeRule: onChangeRule,
          ),
          const SizedBox(height: AppSpacing.lg),
          EteeloKpiBand(
            cards: recoverySimulationCards(
              simulation: simulation,
              targetedDescription: recoveryTargetedDescription(
                rule,
                thresholdInCents,
                l10n,
              ),
              unmanageableBelow: unmanageableBelow,
              l10n: l10n,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          narrow
              ? RecoverySimulationCards(
                  rows: rows,
                  unmanageableBelow: unmanageableBelow,
                  onClassTapped: _open,
                )
              : RecoverySimulationTable(
                  rows: rows,
                  unmanageableBelow: unmanageableBelow,
                  onClassTapped: _open,
                ),
          const SizedBox(height: AppSpacing.gridGap),
          RecoverySimulationNote(simulation: simulation),
        ],
      ),
    );
  }

  void _open(RecoverySimulationRow row) {
    if (row.targetedStudents > 0) onClassTapped(row);
  }
}
