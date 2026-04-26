import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section formulaire identité du payeur (Nom / Prénom / Post-nom).
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

    return FinanceSectionCard(
      gradientColors: const [
        AppColors.financeDetailInfoSurface,
        AppColors.financeDetailCard,
      ],
      borderColor: AppColors.financeDetailAccent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: Icons.person_outline,
            title: l10n.facturationCreatePaymentPayerSectionTitle,
            accent: AppColors.financeDetailAccent,
            accentSoft: AppColors.financeDetailAccentSoft,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          FinanceTextFormField(
            controller: lastNameController,
            label: l10n.facturationCreatePaymentPayerLastNameLabel,
            hint: l10n.facturationCreatePaymentPayerLastNameHint,
            accentColor: AppColors.financeDetailAccent,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.facturationCreatePaymentPayerFieldRequired
                : null,
            readOnly: readOnly,
            inputFormatters: nameInputFormatters,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          FinanceTextFormField(
            controller: firstNameController,
            label: l10n.facturationCreatePaymentPayerFirstNameLabel,
            hint: l10n.facturationCreatePaymentPayerFirstNameHint,
            accentColor: AppColors.financeDetailAccent,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.facturationCreatePaymentPayerFieldRequired
                : null,
            readOnly: readOnly,
            inputFormatters: nameInputFormatters,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          FinanceTextFormField(
            controller: middleNameController,
            label: l10n.facturationCreatePaymentPayerMiddleNameLabel,
            hint: l10n.facturationCreatePaymentPayerMiddleNameHint,
            accentColor: AppColors.financeDetailAccent,
            readOnly: readOnly,
            inputFormatters: nameInputFormatters,
          ),
        ],
      ),
    );
  }
}
