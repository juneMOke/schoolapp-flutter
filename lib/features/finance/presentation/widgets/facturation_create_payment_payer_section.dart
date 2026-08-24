import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/formatters/text_capitalization_formatters.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc identité du payeur de la modale d'encaissement (spec MODALE-12).
///
/// Grille 3 colonnes (Nom · Post-nom · Prénom) qui s'empile sous une largeur
/// contrainte, suivie du téléphone. Le Post-nom est le seul champ facultatif —
/// les autres portent l'étoile du socle, et la validité est gardée par la
/// modale (cf. `_payerValid`).
///
/// Le bouton « Choisir un payeur » ouvre l'annuaire local : le même parent
/// revient chaque trimestre, et le retrouver doit coûter un tap plutôt que
/// quatre champs.
class FacturationCreatePaymentPayerSection extends StatelessWidget {
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController phoneController;
  final bool readOnly;

  /// Ouverture de la popin de sélection. `null` la retire — c'est ce qui arrive
  /// pendant un encaissement en vol, où plus rien ne doit changer sous le
  /// formulaire.
  final VoidCallback? onPickPayer;

  /// Message d'erreur du téléphone (numéro incomplet), ou `null`.
  final String? phoneErrorText;

  const FacturationCreatePaymentPayerSection({
    super.key,
    required this.lastNameController,
    required this.firstNameController,
    required this.middleNameController,
    required this.phoneController,
    this.onPickPayer,
    this.phoneErrorText,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const nameInputFormatters = [WordCapitalizationInputFormatter()];

    final lastName = FinanceTextFormField(
      controller: lastNameController,
      label: l10n.facturationCreatePaymentPayerLastNameLabel,
      hint: l10n.facturationCreatePaymentPayerLastNameHint,
      accentColor: AppColors.bleuArdoise,
      readOnly: readOnly,
      isRequired: true,
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
      label: l10n.facturationCreatePaymentPayerFirstNameLabel,
      hint: l10n.facturationCreatePaymentPayerFirstNameHint,
      accentColor: AppColors.bleuArdoise,
      readOnly: readOnly,
      isRequired: true,
      inputFormatters: nameInputFormatters,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.facturationCreatePaymentPayerSectionTitle),
        const SizedBox(height: AppDimensions.spacingS),
        _PickPayerBar(
          help: l10n.facturationCreatePaymentPayerPickHelp,
          actionLabel: l10n.facturationCreatePaymentPayerPickAction,
          onPressed: readOnly ? null : onPickPayer,
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
        const SizedBox(height: AppDimensions.spacingM),
        // Le socle téléphone plutôt qu'un champ texte : il tient l'indicatif à
        // part, ne rend que de l'E.164 au contrôleur, et comprend les écritures
        // héritées d'un payeur repris de l'annuaire (`0816939060`).
        EteeloPhoneInput(
          controller: phoneController,
          label: l10n.facturationCreatePaymentPayerPhoneLabel,
          required: true,
          readOnly: readOnly,
          errorText: phoneErrorText,
          dialCodeSemanticLabel: l10n.phoneNumberCountryCodeLabel,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.person_outline,
          size: AppDimensions.detailHeaderIconSize,
          color: AppColors.bleuArdoise,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        // `Expanded` : le titre revient à la ligne au lieu de déborder. Dans la
        // modale ouverte sur un téléphone étroit il ne reste que ~280 dp à
        // cette ligne, quand le libellé en réclame 66 de plus.
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.bleuProfond,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rappel + bouton d'ouverture de l'annuaire des payeurs.
///
/// Se replie en colonne quand la largeur ne suffit plus : le bouton ne doit
/// jamais écraser le texte au point de le rendre illisible, ni déborder.
class _PickPayerBar extends StatelessWidget {
  final String help;
  final String actionLabel;
  final VoidCallback? onPressed;

  const _PickPayerBar({
    required this.help,
    required this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final helpText = Text(
      help,
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
    );
    // `fullWidth: false` : un bouton posé en ligne sans largeur intrinsèque
    // hérite du thème pleine largeur et fait lever la mise en page.
    final button = EteeloButton.secondary(
      label: actionLabel,
      icon: Icons.person_search_outlined,
      fullWidth: false,
      onPressed: onPressed,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              helpText,
              const SizedBox(height: AppDimensions.spacingS),
              Align(alignment: Alignment.centerLeft, child: button),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: helpText),
            const SizedBox(width: AppDimensions.spacingM),
            button,
          ],
        );
      },
    );
  }
}
