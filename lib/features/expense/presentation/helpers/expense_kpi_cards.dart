import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une carte de montant qui dit la doctrine bi-devise (§12) :
///
/// - lecture en dollars possible → la valeur est la **lecture** ; dès qu'une
///   autre devise s'y mêle, la sous-ligne commence par la **paire brute** (le
///   chiffre converti n'est jamais le seul lu), puis la mention de la carte ;
/// - lecture impossible (A5, pas de taux publié) → une ligne **par devise**,
///   jamais additionnées, jamais converties au jugé.
EteeloKpiCardData expenseMoneyKpi({
  required AppLocalizations l10n,
  required String label,
  required ExpenseTotals totals,
  required Color accent,
  required Color accentSoft,
  required IconData icon,
  String? subline,
  VoidCallback? onTap,
}) {
  if (totals.bag.isEmpty) {
    return EteeloKpiCardData(
      label: label,
      valueText: ExpenseMoneyText.usd(0),
      accent: accent,
      accentSoft: accentSoft,
      icon: icon,
      subline: subline,
      onTap: onTap,
    );
  }
  if (totals.usdCents == null) {
    return EteeloKpiCardData(
      label: label,
      valueLines: ExpenseMoneyText.lines(totals.bag),
      accent: accent,
      accentSoft: accentSoft,
      icon: icon,
      subline: subline,
      onTap: onTap,
    );
  }
  final reading = ExpenseMoneyText.reading(totals);
  final pair = reading.pair;
  return EteeloKpiCardData(
    label: label,
    valueText: reading.primary,
    accent: accent,
    accentSoft: accentSoft,
    icon: icon,
    subline: pair == null
        ? subline
        : (subline == null ? pair : l10n.expenseJoin(pair, subline)),
    onTap: onTap,
  );
}
