import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
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
            inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
          ),
        ),
        WizardGridField(
          EteeloTextInput(
            label: l10n.lastName,
            controller: lastNameController,
            required: true,
            readOnly: !isEditable || identityReadOnly,
            inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
          ),
        ),
        WizardGridField(
          EteeloTextInput(
            label: l10n.surname,
            controller: surnameController,
            readOnly: !isEditable || identityReadOnly,
            inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
          ),
        ),
        WizardGridField(
          EteeloTextInput(
            label: l10n.phoneNumberLabel,
            controller: phoneController,
            keyboardType: EteeloTextInputType.phone,
            required: true,
            readOnly: !isEditable || identityReadOnly,
            placeholder: l10n.phoneNumberHelp,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\- ]')),
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
      ],
    );
  }
}
