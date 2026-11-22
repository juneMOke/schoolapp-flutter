import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les couleurs de sens du bloc E : rouge « à relancer », vert « en ordre »,
/// bleu « tous » (spec §4.6 E : manquant, encaisse, attendu).
abstract final class RecoveryStudentsTones {
  /// Force de teinte des fonds pâles (onglet actif, cadre de la liste,
  /// lignes) — `#FDF3F1`, `#F3F9F4`, `#F2F6F9` sur la maquette.
  static const softPercent = 6;

  /// Bord du tableau des élèves (terre cuite à 26 %).
  static const listBorderPercent = 26;

  /// Fond d'une ligne survolée ou focalisée au clavier.
  static const hoverPercent = 12;

  /// Fond d'un onglet inactif (`color-mix(… 7%, surface)`).
  static const idleTabPercent = 7;

  /// Bord du cadre de la liste et de l'onglet actif (35 % dans la bordure).
  static const frameBorderPercent = 35;

  static Color of(RecoveryTab tab) => switch (tab) {
    RecoveryTab.toChase => DashboardSense.manquant,
    RecoveryTab.inOrder => DashboardSense.encaisse,
    RecoveryTab.all => DashboardSense.attendu,
  };

  static Color soft(Color tone) => DashboardTones.teinte(tone, softPercent);

  /// L'encre lisible de la ligne « Donc pas en ordre ».
  static Color get contraryInk =>
      DashboardTones.encreLisible(DashboardSense.manquant);

  /// La ligne ambre des deux devises cochées.
  static const mixedInk = AppColors.ambreInk;
}

/// Le seuil d'« a payé au moins », formaté dans la devise du périmètre ;
/// `null` sans montant ou sans devise unique.
String? recoveryThresholdText(int? thresholdInCents, List<String> currencies) {
  if (thresholdInCents == null || currencies.length != 1) return null;
  return MoneyFormat.format(Money(thresholdInCents, currencies.single));
}

/// Les deux verbes d'une règle (`recPhrase`) : ce que font les élèves en
/// ordre, puis ceux qui ne le sont pas.
({String ok, String ko}) recoveryRuleVerbs(
  AppLocalizations l10n,
  RecoveryRuleKind rule,
  String? threshold,
) => switch (rule) {
  RecoveryRuleKind.atLeast when threshold != null => (
    ok: l10n.recoveryStudentsVerbOkAtLeast(threshold),
    ko: l10n.recoveryStudentsVerbKoAtLeast(threshold),
  ),
  RecoveryRuleKind.fullySettled => (
    ok: l10n.recoveryStudentsVerbOkFullySettled,
    ko: l10n.recoveryStudentsVerbKoFullySettled,
  ),
  // « Au moins » sans montant : le serveur répond sur la règle par défaut
  // (`RecoveryQuestion.effectiveRule`), la ligne d'aide la suit.
  _ => (
    ok: l10n.recoveryStudentsVerbOkSomePayment,
    ko: l10n.recoveryStudentsVerbKoSomePayment,
  ),
};

/// « Donc pas en ordre : … » (§7 `regle.contraire`).
String recoveryRuleContrary(
  AppLocalizations l10n,
  RecoveryRuleKind rule,
  String? threshold,
) => switch (rule) {
  RecoveryRuleKind.somePayment => l10n.recoveryStudentsRuleContrarySomePayment,
  RecoveryRuleKind.fullySettled =>
    l10n.recoveryStudentsRuleContraryFullySettled,
  RecoveryRuleKind.atLeast =>
    threshold == null
        ? l10n.recoveryStudentsRuleContraryAtLeastEmpty
        : l10n.recoveryStudentsRuleContraryAtLeast(threshold),
};

/// Le message d'une liste vide, selon l'onglet et la recherche (§7
/// `liste.vide`).
String recoveryEmptyText(
  AppLocalizations l10n,
  RecoveryTab tab,
  String search,
) {
  final s = search.trim();
  if (s.isNotEmpty) return l10n.recoveryStudentsEmptySearch(s);
  return switch (tab) {
    RecoveryTab.toChase => l10n.recoveryStudentsEmptyToChase,
    RecoveryTab.inOrder => l10n.recoveryStudentsEmptyInOrder,
    RecoveryTab.all => l10n.recoveryStudentsEmptyAll,
  };
}

/// Une liste de montants par devise, une ligne par devise (dollars, puis
/// francs) ; jamais additionnés. Sans montant, un zéro dans chaque devise
/// du périmètre ([currencies]).
List<String> recoveryAmountLines(List<Money> amounts, List<String> currencies) {
  final source = amounts.isNotEmpty
      ? amounts
      : [for (final c in currencies) Money(0, c)];
  final sorted = [...source]
    ..sort((a, b) => _currencyRank(a.currency) - _currencyRank(b.currency));
  return [for (final m in sorted) MoneyFormat.format(m)];
}

int _currencyRank(String currency) => currency.toUpperCase() == 'USD' ? 0 : 1;
