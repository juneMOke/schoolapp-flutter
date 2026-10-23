import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sale_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les élèves servis par une vente, chacun une fois, avec sa classe.
///
/// Le même renseignement que la ligne du tableau de bord : ouvrir la fiche ne
/// doit pas en apprendre MOINS que la liste d'où l'on vient.
class BoutiqueSaleDetailBeneficiaries extends StatelessWidget {
  final List<SaleBeneficiary> beneficiaries;

  const BoutiqueSaleDetailBeneficiaries({
    super.key,
    required this.beneficiaries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < beneficiaries.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
          _BeneficiaryRow(beneficiary: beneficiaries[i]),
        ],
      ],
    );
  }
}

class _BeneficiaryRow extends StatelessWidget {
  final SaleBeneficiary beneficiary;

  const _BeneficiaryRow({required this.beneficiary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Un élève que le poste ne connaît pas reste LISTÉ : taire qu'un enfant a
    // été servi ferait croire à une vente au comptant.
    final name = beneficiary.fullName;
    final classLabel = beneficiary.classLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              name ?? l10n.boutiqueSaleDetailStudentUnknown,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: name == null ? FontWeight.w400 : FontWeight.w600,
                color: name == null
                    ? AppColors.textMuted
                    : AppColors.bleuProfond,
                fontStyle: name == null ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            classLabel ?? l10n.boutiqueSaleDetailStudentNoClass,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontStyle: classLabel == null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
