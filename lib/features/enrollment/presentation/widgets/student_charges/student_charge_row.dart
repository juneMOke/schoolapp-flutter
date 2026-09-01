import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargeRow extends StatelessWidget {
  final StudentCharge studentCharge;
  final TextEditingController amountController;
  final bool isEditable;
  final String currency;
  final String? amountErrorText;
  final ValueChanged<String> onAmountChanged;

  /// Mode étroit (téléphone) : colonne Actions masquée + montant élargi, pour
  /// éviter la troncature. Voir [AppBreakpoints.studentChargesActionColMin].
  final bool compact;

  const StudentChargeRow({
    super.key,
    required this.studentCharge,
    required this.amountController,
    required this.isEditable,
    required this.currency,
    required this.amountErrorText,
    required this.onAmountChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // La cascade était INVERSE de celle du guichet : la nature d'abord, le
    // libellé seulement si la nature était inconnue. Deux écrans, deux règles,
    // la même donnée — et sur un minerval en tranches, sept lignes identiques.
    final designation = chargeDesignation(studentCharge, l10n);
    final dueAt = studentCharge.dueAt == null
        ? null
        : DateTime.tryParse(studentCharge.dueAt!);
    final secondaryText = dueAt != null
        ? l10n.studentChargeDueAtLabel(dueAt)
        : studentCharge.feeCode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            // En étroit, on réduit la part du libellé (il s'enroule) au profit
            // du montant qui, lui, ne doit pas être tronqué.
            flex: compact ? 4 : 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  designation,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  secondaryText,
                  style: AppTextStyles.codeMuted.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            flex: compact ? 5 : 4,
            child: CurrencyField(
              controller: amountController,
              currency: currency,
              enabled: isEditable,
              labelText: l10n.studentChargesAmountColumn,
              errorText: amountErrorText,
              onChanged: onAmountChanged,
            ),
          ),
          // Colonne Actions (icône edit/lock) masquée en étroit : 2 colonnes.
          if (!compact) ...[
            const SizedBox(width: AppDimensions.spacingM),
            SizedBox(
              width: AppDimensions.minTouchTarget,
              child: Center(
                child: Icon(
                  isEditable ? Icons.edit_outlined : Icons.lock_outline,
                  size: AppDimensions.detailMiniIconSize,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
