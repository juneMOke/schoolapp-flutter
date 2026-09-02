import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc identité du payeur de la page d'encaissement (spec MODALE-12).
///
/// Grille 3 colonnes (Nom · Post-nom · Prénom) qui s'empile sous une largeur
/// contrainte, suivie du téléphone.
///
/// **Les quatre champs sont facultatifs** (V114 serveur) : aucune étoile, et
/// une mention qui le dit. L'exigence se payait comptant au guichet — la file
/// attend pendant qu'on demande son état civil à qui tend les billets, et le
/// guichetier finit par taper « X ». Un payeur ABSENT vaut mieux qu'un payeur
/// INVENTÉ : les imputations nomment toujours l'élève et les créances soldées.
///
/// Seul le FORMAT du numéro reste gardé, et seulement s'il est entamé
/// (`phoneErrorText`).
///
/// **Tous les champs sont ceux du socle** (`EteeloTextInput` /
/// `EteeloPhoneInput`), libellé au-dessus du champ. Ils portaient jusqu'ici la
/// décoration Finance, à libellé flottant DANS la bordure : le téléphone, lui,
/// ne peut pas s'y plier sans qu'on recopie sa conversion national↔E.164 et son
/// repli numéro étranger. C'est donc le téléphone qui donne le format, et le
/// reste de la section qui s'y range — une section homogène, et la même écriture
/// d'un champ que partout ailleurs dans l'application.
///
/// La capitalisation n'est plus déclarée : c'est le DÉFAUT du socle (mot par
/// mot pour une identité, règle non négociable #11). C'est l'exception qui se
/// déclare.
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

    final lastName = EteeloTextInput(
      controller: lastNameController,
      label: l10n.facturationCreatePaymentPayerLastNameLabel,
      placeholder: l10n.facturationCreatePaymentPayerLastNameHint,
      readOnly: readOnly,
      textInputAction: TextInputAction.next,
    );
    final middleName = EteeloTextInput(
      controller: middleNameController,
      label: l10n.facturationCreatePaymentPayerMiddleNameLabel,
      placeholder: l10n.facturationCreatePaymentPayerMiddleNameHint,
      readOnly: readOnly,
      textInputAction: TextInputAction.next,
    );
    final firstName = EteeloTextInput(
      controller: firstNameController,
      label: l10n.facturationCreatePaymentPayerFirstNameLabel,
      placeholder: l10n.facturationCreatePaymentPayerFirstNameHint,
      readOnly: readOnly,
      textInputAction: TextInputAction.next,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Même en-tête que les autres sections Finance : la carte de la page
        // remplace le bandeau sombre de l'ancienne popin.
        FinanceSectionHeader(
          icon: Icons.person_outline,
          title: l10n.facturationCreatePaymentPayerSectionTitle,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.surfaceAlt,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppDimensions.spacingM),
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
        // Il tient l'indicatif à part, ne rend que de l'E.164 au contrôleur, et
        // comprend les écritures héritées d'un payeur repris de l'annuaire
        // (`0816939060`). C'est lui qui a fixé le format de toute la section.
        EteeloPhoneInput(
          controller: phoneController,
          label: l10n.facturationCreatePaymentPayerPhoneLabel,
          readOnly: readOnly,
          errorText: phoneErrorText,
          dialCodeSemanticLabel: l10n.phoneNumberCountryCodeLabel,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // Dire que c'est facultatif VAUT l'espace : sans mention, un guichetier
        // qui a toujours dû remplir ces champs continuera de les remplir, et
        // l'assouplissement n'aura rien changé à la file d'attente.
        Text(
          l10n.facturationCreatePaymentPayerOptionalNotice,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
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
