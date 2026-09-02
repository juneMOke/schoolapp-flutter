import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Frais à régler » de la page d'encaissement : la liste des postes
/// payables, ou la carte « tout est soldé » quand il n'y a plus rien à
/// encaisser.
///
/// Même anatomie que les sections de la fiche de facturation (carte, en-tête à
/// badge, liseré) : l'encaissement n'est plus une popin posée par-dessus la
/// fiche, c'est un écran du même module.
class FacturationCreatePaymentChargesSection extends StatelessWidget {
  final List<FacturationChargeEntry> entries;

  /// `null` fige la section — c'est ce qui arrive pendant un encaissement en
  /// vol, où plus rien ne doit bouger sous le guichetier.
  final void Function(FacturationChargeEntry entry, bool value)? onToggle;
  final void Function(FacturationChargeEntry entry)? onSettleAll;

  /// Une mention posée en tête de section — aujourd'hui l'absence de taux, qui
  /// se dit plutôt que de laisser un écran où il ne se passe rien. `null` dans
  /// le cas courant.
  final Widget? settlement;

  /// Les devises proposables pour CE frais, la sienne en tête. Moins de deux ⇒
  /// la ligne n'affiche aucun sélecteur.
  final List<String> Function(FacturationChargeEntry entry)? currencyOptionsOf;

  /// Le taux appliqué à cette ligne, déjà rendu. `null` quand elle ne convertit
  /// pas.
  final String? Function(FacturationChargeEntry entry)? rateLabelOf;

  /// La monnaie à rendre sur cette ligne, déjà rendue.
  final String? Function(FacturationChargeEntry entry)? changeLabelOf;

  /// La devise de règlement vient de changer sur cette ligne.
  final void Function(FacturationChargeEntry entry, String currency)?
  onTenderCurrencyChanged;

  /// L'un des deux montants vient d'être tapé : l'autre se recalcule.
  final void Function(FacturationChargeEntry entry)? onAllocationEdited;
  final void Function(FacturationChargeEntry entry)? onTenderEdited;

  const FacturationCreatePaymentChargesSection({
    super.key,
    required this.entries,
    required this.onToggle,
    required this.onSettleAll,
    this.settlement,
    this.currencyOptionsOf,
    this.rateLabelOf,
    this.changeLabelOf,
    this.onTenderCurrencyChanged,
    this.onAllocationEdited,
    this.onTenderEdited,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FinanceSectionCard(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: Icons.receipt_long_outlined,
            title: l10n.facturationCreatePaymentChargesToSettleTitle,
            subtitle: l10n.facturationCreatePaymentChargesToSettleSubtitle,
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.surfaceAlt,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.spacingM),
          if (settlement != null) ...[
            settlement!,
            const SizedBox(height: AppDimensions.spacingM),
          ],
          if (entries.isEmpty)
            const _AllSettledCard()
          else
            for (var i = 0; i < entries.length; i++) ...[
              FacturationCreatePaymentChargeAllocationLine(
                charge: entries[i].charge,
                selected: entries[i].selected,
                amountController: entries[i].controller,
                tenderController: entries[i].tenderController,
                onSelectedChanged: (v) => onToggle?.call(entries[i], v),
                onSettleAll: () => onSettleAll?.call(entries[i]),
                currencyOptions:
                    currencyOptionsOf?.call(entries[i]) ?? const [],
                tenderCurrency: entries[i].effectiveTenderCurrency,
                onTenderCurrencyChanged: (currency) =>
                    onTenderCurrencyChanged?.call(entries[i], currency),
                onAllocationEdited: () => onAllocationEdited?.call(entries[i]),
                onTenderEdited: () => onTenderEdited?.call(entries[i]),
                rateLabel: rateLabelOf?.call(entries[i]),
                changeLabel: changeLabelOf?.call(entries[i]),
              ),
              if (i < entries.length - 1)
                const SizedBox(height: AppDimensions.spacingS),
            ],
        ],
      ),
    );
  }
}

/// Carte « Tous les frais sont déjà soldés ».
class _AllSettledCard extends StatelessWidget {
  const _AllSettledCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.feeStatusPaidSoft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.feeStatusPaidBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: AppColors.feeStatusPaid,
            size: AppDimensions.detailHeaderIconSize,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.facturationCreatePaymentAllFeesSettled,
              style: AppTextStyles.body.copyWith(
                color: AppColors.feeStatusPaid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
