import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Des montants de plusieurs devises dans une phrase : « 7 680 $ et
/// 340 000 FC » — **jamais additionnés**, chacun dans sa devise. Les devises
/// à zéro s'effacent quand une autre porte un montant.
String recoveryAmountsText(List<Money> amounts, AppLocalizations l10n) {
  final shown = amounts.where((m) => !m.isZero).toList();
  final list = shown.isEmpty ? amounts.take(1).toList() : shown;
  if (list.isEmpty) return MoneyFormat.compact(const Money(0, 'USD'));
  return list
      .map(MoneyFormat.compact)
      .reduce((a, b) => l10n.recoveryAmountsAnd(a, b));
}

/// Vrai quand aucune devise ne porte de montant.
bool recoveryAllZero(List<Money> amounts) => amounts.every((m) => m.isZero);

/// La règle telle que le serveur l'a appliquée : « au moins » sans montant
/// retombe sur « a payé quelque chose » (R8).
RecoveryRuleKind recoveryEffectiveRule(
  RecoveryRuleKind rule,
  int? thresholdInCents,
) => rule == RecoveryRuleKind.atLeast && thresholdInCents == null
    ? RecoveryRuleKind.somePayment
    : rule;

/// Qui la simulation vise, en toutes lettres (le contraire de la règle R8) :
/// « N'ont rien payé » · « N'ont pas tout soldé » · « Ont payé moins que
/// {montant} ». [currency] est l'unique devise du périmètre ; « au moins »
/// n'existe pas en mixte.
String recoveryTargetedLabel(
  RecoveryRuleKind rule,
  int? thresholdInCents,
  String? currency,
  AppLocalizations l10n,
) => switch (recoveryEffectiveRule(rule, thresholdInCents)) {
  RecoveryRuleKind.somePayment => l10n.recoverySimulationCriterionNoPayment,
  RecoveryRuleKind.fullySettled => l10n.recoverySimulationCriterionNotSettled,
  RecoveryRuleKind.atLeast => l10n.recoverySimulationCriterionBelow(
    currency == null
        ? MoneyFormat.amountOnly(Money(thresholdInCents!, 'USD'))
        : MoneyFormat.compact(Money(thresholdInCents!, currency)),
  ),
};

/// La sous-ligne du pavé « Élèves visés » (`REC_CRITERES.desc`).
String recoveryTargetedDescription(
  RecoveryRuleKind rule,
  int? thresholdInCents,
  AppLocalizations l10n,
) => switch (recoveryEffectiveRule(rule, thresholdInCents)) {
  RecoveryRuleKind.somePayment => l10n.recoverySimulationTargetedNoPayment,
  RecoveryRuleKind.fullySettled => l10n.recoverySimulationTargetedNotSettled,
  RecoveryRuleKind.atLeast => l10n.recoverySimulationTargetedBelow,
};

/// L'unique devise du périmètre, ou `null` en mixte.
String? recoverySoleCurrency(RecoveryDashboard dashboard) =>
    dashboard.currencies.length == 1 ? dashboard.currencies.single : null;

/// Les lignes dans l'ordre du serveur (les plus touchées d'abord), la
/// rubrique « Non affectés » toujours en dernier.
List<RecoverySimulationRow> recoverySimulationOrdered(
  RecoverySimulation simulation,
) => [
  for (final row in simulation.rows)
    if (!row.isUnassigned) row,
  for (final row in simulation.rows)
    if (row.isUnassigned) row,
];
