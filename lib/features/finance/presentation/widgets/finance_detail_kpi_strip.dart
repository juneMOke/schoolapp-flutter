import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bande KPI du détail Facturation (spec §07).
///
/// Réutilise le composant DS partagé [EteeloKpiBand]/[KpiCard] — mêmes cartes et même
/// responsivité (grille auto-fill) que les tableaux de bord. Montants en
/// **cents** → formatés en devise ; le solde restant est teinté sémantiquement
/// (rouge s'il reste à payer, vert s'il est soldé).
class FinanceDetailKpiBand extends StatelessWidget {
  final bool hasCharges;
  final double totalDueCents;
  final double alreadyPaidCents;
  final double remainingCents;
  final String currency;

  const FinanceDetailKpiBand({
    super.key,
    required this.hasCharges,
    required this.totalDueCents,
    required this.alreadyPaidCents,
    required this.remainingCents,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDue = remainingCents > 0;

    return EteeloKpiBand(
      cards: [
        EteeloKpiCardData(
          label: l10n.facturationDetailHeaderKpiTotalDue,
          valueText: _value(l10n, totalDueCents),
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.billingHelpSurface,
          icon: Icons.receipt_long_rounded,
        ),
        EteeloKpiCardData(
          label: l10n.facturationDetailHeaderKpiAlreadyPaid,
          valueText: _value(l10n, alreadyPaidCents),
          accent: AppColors.feeStatusPaid,
          accentSoft: AppColors.feeStatusPaidSoft,
          icon: Icons.payments_rounded,
        ),
        EteeloKpiCardData(
          label: l10n.facturationDetailHeaderKpiRemaining,
          valueText: _value(l10n, remainingCents),
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

  String _value(AppLocalizations l10n, double cents) {
    if (!hasCharges) return l10n.facturationDetailUnknownValue;
    final amount = formatMonetaryAmount(cents / 100);
    return currency.trim().isEmpty ? amount : '$amount $currency';
  }
}
