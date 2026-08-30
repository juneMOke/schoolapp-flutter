import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bande KPI du détail Facturation (spec §07).
///
/// Réutilise le composant DS partagé [EteeloKpiBand]/`KpiCard` — mêmes cartes et
/// même responsivité (grille auto-fill) que les tableaux de bord. Le solde
/// restant est teinté sémantiquement (rouge s'il reste à payer, vert s'il est
/// soldé).
///
/// ## Trois sacs, pas trois nombres
///
/// Un élève peut devoir 425,00 $ **et** 90 000 FC. Ces deux montants ne se
/// somment pas — leur total n'existe pas — donc chaque carte porte une ligne
/// par devise plutôt qu'un chiffre unique étiqueté avec la première devise
/// venue, ce que cet écran faisait.
///
/// En mono-devise, le rendu est **exactement** celui d'avant : un sac à une
/// entrée donne une ligne.
class FinanceDetailKpiBand extends StatelessWidget {
  final bool hasCharges;
  final MoneyBag totalDue;
  final MoneyBag alreadyPaid;
  final MoneyBag remaining;

  const FinanceDetailKpiBand({
    super.key,
    required this.hasCharges,
    required this.totalDue,
    required this.alreadyPaid,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // « Il reste quelque chose, quelque part » : dans n'importe quelle devise.
    final isDue = !remaining.isAllZero;

    return EteeloKpiBand(
      cards: [
        EteeloKpiCardData(
          label: l10n.facturationDetailHeaderKpiTotalDue,
          valueLines: _lines(l10n, totalDue),
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.billingHelpSurface,
          icon: Icons.receipt_long_rounded,
        ),
        EteeloKpiCardData(
          label: l10n.facturationDetailHeaderKpiAlreadyPaid,
          valueLines: _lines(l10n, alreadyPaid),
          accent: AppColors.feeStatusPaid,
          accentSoft: AppColors.feeStatusPaidSoft,
          icon: Icons.payments_rounded,
        ),
        EteeloKpiCardData(
          label: l10n.facturationDetailHeaderKpiRemaining,
          valueLines: _lines(l10n, remaining),
          accent: isDue ? AppColors.feeStatusDue : AppColors.feeStatusPaid,
          accentSoft: isDue
              ? AppColors.feeStatusDueSoft
              : AppColors.feeStatusPaidSoft,
          icon: isDue
              ? Icons.pending_actions_rounded
              : Icons.check_circle_rounded,
        ),
      ],
    );
  }

  /// Une ligne par devise.
  ///
  /// Sans créance, la valeur est **inconnue** — et non « zéro », qu'il faudrait
  /// libeller dans une devise que personne n'a choisie. Un sac vide sur un
  /// élève qui a bien des créances ne peut pas arriver : les sacs sont
  /// construits à partir d'elles.
  List<String> _lines(AppLocalizations l10n, MoneyBag bag) {
    if (!hasCharges || bag.isEmpty) {
      return [l10n.facturationDetailUnknownValue];
    }
    return [for (final amount in bag.entries) MoneyFormat.format(amount)];
  }
}
