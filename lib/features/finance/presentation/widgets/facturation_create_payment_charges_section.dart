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

  const FacturationCreatePaymentChargesSection({
    super.key,
    required this.entries,
    required this.onToggle,
    required this.onSettleAll,
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
          if (entries.isEmpty)
            const _AllSettledCard()
          else
            for (var i = 0; i < entries.length; i++) ...[
              FacturationCreatePaymentChargeAllocationLine(
                charge: entries[i].charge,
                selected: entries[i].selected,
                amountController: entries[i].controller,
                onSelectedChanged: (v) => onToggle?.call(entries[i], v),
                onSettleAll: () => onSettleAll?.call(entries[i]),
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
