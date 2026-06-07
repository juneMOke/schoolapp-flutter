import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc identité du payeur de la modale d'encaissement (spec MODALE-12).
///
/// Grille 3 colonnes (Nom · Post-nom · Prénom) qui s'empile sous une largeur
/// contrainte. Le Post-nom est facultatif (la validité ne dépend que de
/// Nom && Prénom, gérée par la modale).
class FacturationCreatePaymentPayerSection extends StatelessWidget {
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final bool readOnly;

  const FacturationCreatePaymentPayerSection({
    super.key,
    required this.lastNameController,
    required this.firstNameController,
    required this.middleNameController,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const nameInputFormatters = [FirstLetterUppercaseTextInputFormatter()];

    final lastName = FinanceTextFormField(
      controller: lastNameController,
      label: '${l10n.facturationCreatePaymentPayerLastNameLabel} *',
      hint: l10n.facturationCreatePaymentPayerLastNameHint,
      accentColor: AppColors.bleuArdoise,
      readOnly: readOnly,
      inputFormatters: nameInputFormatters,
    );
    final middleName = FinanceTextFormField(
      controller: middleNameController,
      label: l10n.facturationCreatePaymentPayerMiddleNameLabel,
      hint: l10n.facturationCreatePaymentPayerMiddleNameHint,
      accentColor: AppColors.bleuArdoise,
      readOnly: readOnly,
      inputFormatters: nameInputFormatters,
    );
    final firstName = FinanceTextFormField(
      controller: firstNameController,
      label: '${l10n.facturationCreatePaymentPayerFirstNameLabel} *',
      hint: l10n.facturationCreatePaymentPayerFirstNameHint,
      accentColor: AppColors.bleuArdoise,
      readOnly: readOnly,
      inputFormatters: nameInputFormatters,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: AppDimensions.detailHeaderIconSize,
              color: AppColors.bleuArdoise,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              l10n.facturationCreatePaymentPayerSectionTitle,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.bleuProfond,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            // Empile en dessous d'un seuil où 3 colonnes deviennent illisibles.
            if (constraints.maxWidth < 460) {
              return Column(
                children: [
                  lastName,
                  const SizedBox(height: AppDimensions.spacingM),
                  middleName,
                  const SizedBox(height: AppDimensions.spacingM),
                  firstName,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lastName),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(child: middleName),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(child: firstName),
              ],
            );
          },
        ),
      ],
    );
  }
}
