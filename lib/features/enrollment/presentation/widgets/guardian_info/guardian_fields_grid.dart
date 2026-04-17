import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianFieldsGrid extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool firstNameChanged;
  final bool lastNameChanged;
  final bool surnameChanged;
  final bool phoneChanged;
  final bool emailChanged;
  final RelationshipType selectedRelationshipType;
  final ValueChanged<RelationshipType> onRelationshipTypeChanged;
  final bool relationshipChanged;
  final bool isEditable;

  const GuardianFieldsGrid({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.phoneController,
    required this.emailController,
    this.firstNameChanged = false,
    this.lastNameChanged = false,
    this.surnameChanged = false,
    this.phoneChanged = false,
    this.emailChanged = false,
    required this.selectedRelationshipType,
    required this.onRelationshipTypeChanged,
    this.relationshipChanged = false,
    this.isEditable = true,
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

  IconData _relationshipIcon(RelationshipType type) {
    return switch (type) {
      RelationshipType.father => Icons.man,
      RelationshipType.mother => Icons.woman,
      RelationshipType.guardian => Icons.supervisor_account,
      RelationshipType.uncle => Icons.man_2,
      RelationshipType.aunt => Icons.woman_2,
      RelationshipType.grandparent => Icons.elderly,
      RelationshipType.other => Icons.person,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final successColor = AppTheme.secondaryColor;
    final surfaceColor = AppTheme.surfaceColor;
    final textSecondaryColor = AppTheme.textSecondaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final width = constraints.maxWidth >= 640
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 20,
          children: [
            EditableField(
              width: width,
              label: l10n.firstName,
              controller: firstNameController,
              requiredField: true,
              helpMessage: l10n.firstNameHelp,
              isChanged: firstNameChanged,
              readOnly: !isEditable,
            ),
            EditableField(
              width: width,
              label: l10n.lastName,
              controller: lastNameController,
              requiredField: true,
              helpMessage: l10n.lastNameHelp,
              isChanged: lastNameChanged,
              readOnly: !isEditable,
            ),
            EditableField(
              width: width,
              label: l10n.surname,
              controller: surnameController,
              helpMessage: l10n.surnameHelp,
              isChanged: surnameChanged,
              readOnly: !isEditable,
            ),
            EditableField(
              width: width,
              label: l10n.phoneNumberLabel,
              controller: phoneController,
              requiredField: true,
              helpMessage: l10n.phoneNumberHelp,
              isChanged: phoneChanged,
              readOnly: !isEditable,
            ),
            EditableField(
              width: width,
              label: l10n.emailLabel,
              controller: emailController,
              requiredField: true,
              helpMessage: l10n.emailLabelHelp,
              isChanged: emailChanged,
              readOnly: !isEditable,
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Relation',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: relationshipChanged ? successColor : textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: RelationshipType.values.map((type) {
                      final isSelected = selectedRelationshipType == type;
                      final activeColor = relationshipChanged ? successColor : primaryColor;

                      return ChoiceChip(
                        avatar: Icon(
                          _relationshipIcon(type),
                          size: 18,
                          color: isSelected ? activeColor : textSecondaryColor,
                        ),
                        label: Text(_relationshipLabel(context, type)),
                        selected: isSelected,
                        onSelected: isEditable
                            ? (selected) {
                                if (selected) onRelationshipTypeChanged(type);
                              }
                            : null,
                        backgroundColor: surfaceColor,
                        selectedColor: activeColor.withValues(alpha: 0.1),
                        checkmarkColor: activeColor,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: isSelected ? activeColor : AppTheme.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? activeColor
                              : Colors.grey.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        elevation: isSelected ? 0 : 0,
                        pressElevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
