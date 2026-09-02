import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/forms/wizard_fields_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianFieldsGrid extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final RelationshipType selectedRelationshipType;
  final ValueChanged<RelationshipType> onRelationshipTypeChanged;
  final bool isEditable;
  final bool isPrimary;
  final ValueChanged<bool?>? onPrimaryChanged;

  /// Tuteur à appeler en urgence pour CET élève. Au plus un par élève :
  /// l'exclusivité est tenue par l'étape, qui connaît toutes les cartes — une
  /// case ne sait rien de ses voisines.
  final bool isEmergencyContact;
  final ValueChanged<bool?>? onEmergencyContactChanged;

  /// true si ce tuteur a été rattaché via "Rechercher un parent" cette
  /// session : verrouille les champs d'IDENTITÉ (nom/postnom/prénom/
  /// téléphone/email) en lecture seule PLEINE COULEUR (pas grisé — convention
  /// projet), pour éviter d'éditer par erreur une fiche parent existante,
  /// potentiellement partagée avec d'autres élèves. Le lien de parenté et le
  /// statut "principal" restent éditables (propres à CET élève).
  final bool identityReadOnly;

  const GuardianFieldsGrid({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.phoneController,
    required this.emailController,
    required this.selectedRelationshipType,
    required this.onRelationshipTypeChanged,
    this.isEditable = true,
    this.isPrimary = false,
    this.onPrimaryChanged,
    this.isEmergencyContact = false,
    this.onEmergencyContactChanged,
    this.identityReadOnly = false,
  });

  String _relationshipLabel(BuildContext context, RelationshipType type) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      RelationshipType.father => l10n.relationshipFather,
      RelationshipType.mother => l10n.relationshipMother,
      RelationshipType.guardian => l10n.relationshipGuardian,
      RelationshipType.uncle => l10n.relationshipUncle,
      RelationshipType.aunt => l10n.relationshipAunt,
      RelationshipType.grandparent => l10n.relationshipGrandparent,
      RelationshipType.other => l10n.relationshipOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return WizardFieldsGrid(
      fields: [
        if (identityReadOnly)
          WizardGridField(
            Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.guardianSearchIdentityLockedHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            fullWidth: true,
          ),
        WizardGridField(
          EteeloTextInput(
            label: l10n.firstName,
            controller: firstNameController,
            required: true,
            readOnly: !isEditable || identityReadOnly,
          ),
        ),
        WizardGridField(
          EteeloTextInput(
            label: l10n.lastName,
            controller: lastNameController,
            required: true,
            readOnly: !isEditable || identityReadOnly,
          ),
        ),
        WizardGridField(
          EteeloTextInput(
            label: l10n.surname,
            controller: surnameController,
            readOnly: !isEditable || identityReadOnly,
          ),
        ),
        WizardGridField(
          // **Facultatif (V117).** Un tuteur sans numéro existe au guichet — le
          // parent qui n'a pas de ligne, celui qui vient inscrire l'enfant d'un
          // frère — et l'exigence ne laissait qu'une issue : en inventer un.
          //
          // La mention dit ce que l'absence coûte, parce que ce n'est pas rien
          // et que ça ne se devine pas : ni notification, ni portail parent, et
          // pas de reprise pour la fratrie. L'opérateur tranche en connaissance
          // de cause au lieu d'être bloqué.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              EteeloPhoneInput(
                label: l10n.phoneNumberLabel,
                controller: phoneController,
                readOnly: !isEditable || identityReadOnly,
                dialCodeSemanticLabel: l10n.phoneNumberCountryCodeLabel,
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                l10n.guardianPhoneNumberOptionalNotice,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        WizardGridField(
          EteeloTextInput(
            label: l10n.emailLabel,
            controller: emailController,
            keyboardType: EteeloTextInputType.email,
            readOnly: !isEditable || identityReadOnly,
            placeholder: l10n.emailLabelHelp,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
        ),
        WizardGridField(
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.withValues(alpha: 0.7),
          ),
          fullWidth: true,
        ),
        WizardGridField(
          EteeloSelectInput<RelationshipType>(
            label: l10n.guardianRelationshipLabel,
            required: true,
            enabled: isEditable,
            readOnly: !isEditable,
            value: selectedRelationshipType,
            placeholder: l10n.guardianRelationshipLabel,
            items: RelationshipType.values
                .map(
                  (type) => EteeloSelectItem<RelationshipType>(
                    value: type,
                    label: _relationshipLabel(context, type),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              onRelationshipTypeChanged(value);
            },
          ),
        ),
        WizardGridField(
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.guardianMarkAsPrimary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Checkbox(
                value: isPrimary,
                onChanged: isEditable ? onPrimaryChanged : null,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        // Contact d'urgence — DÉSÉLECTIONNABLE, contrairement au tuteur
        // principal : « aucun contact désigné » est un état légitime du
        // dossier, et le serveur distingue « retirer » de « ne rien dire ».
        WizardGridField(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.guardianEmergencyContactLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l10n.guardianEmergencyContactHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // **Pas de filtre `isEditable` ici**, contrairement au tuteur
              // principal : la désignation reste ouverte sur un dossier en
              // consultation, où elle part par le chemin online. C'est
              // l'appelant qui décide, en fournissant — ou non — le callback ;
              // deux conditions concurrentes finiraient par diverger.
              //
              // Masquée sans la permission d'écriture (un CTA absent dit « pas
              // vous »), gelée en session lecture seule (un CTA estompé dit
              // « pas maintenant ») : deux causes, deux formes.
              PermissionGate(
                requires: const [Perm.studentWrite],
                child: SessionWriteGate(
                  child: Checkbox(
                    value: isEmergencyContact,
                    onChanged: onEmergencyContactChanged,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
