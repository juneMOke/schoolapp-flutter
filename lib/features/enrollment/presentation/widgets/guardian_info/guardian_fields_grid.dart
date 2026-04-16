import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianFieldsGrid extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController surnameController;
  final TextEditingController idController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool firstNameChanged;
  final bool lastNameChanged;
  final bool surnameChanged;
  final bool idChanged;
  final bool phoneChanged;
  final bool emailChanged;
  final bool idReadOnly;
  final RelationshipType selectedRelationshipType;
  final ValueChanged<RelationshipType> onRelationshipTypeChanged;
  final bool relationshipChanged;
  final bool isEditable;

  const GuardianFieldsGrid({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.surnameController,
    required this.idController,
    required this.phoneController,
    required this.emailController,
    this.firstNameChanged = false,
    this.lastNameChanged = false,
    this.surnameChanged = false,
    this.idChanged = false,
    this.phoneChanged = false,
    this.emailChanged = false,
    this.idReadOnly = false,
    required this.selectedRelationshipType,
    required this.onRelationshipTypeChanged,
    this.relationshipChanged = false,
    this.isEditable = true,
  });

  String _relationshipLabel(RelationshipType type) {
    return switch (type) {
      RelationshipType.father => 'FATHER',
      RelationshipType.mother => 'MOTHER',
      RelationshipType.guardian => 'GUARDIAN',
      RelationshipType.uncle => 'UNCLE',
      RelationshipType.aunt => 'AUNT',
      RelationshipType.grandparent => 'GRANDPARENT',
      RelationshipType.other => 'OTHER',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final width = constraints.maxWidth >= 640
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
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
              label: l10n.identificationNumberLabel,
              controller: idController,
              requiredField: true,
              helpMessage: l10n.identificationNumberHelp,
              isChanged: idChanged,
              readOnly: idReadOnly || !isEditable,
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
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Relation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: relationshipChanged
                          ? const Color(0xFF15803D)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<RelationshipType>(
                    key: ValueKey<RelationshipType>(selectedRelationshipType),
                    initialValue: selectedRelationshipType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: relationshipChanged
                          ? const Color(0xFFF0FDF4)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: relationshipChanged
                              ? const Color(0xFF16A34A).withValues(alpha: 0.55)
                              : Colors.grey.withValues(alpha: 0.35),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF16A34A),
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: RelationshipType.values
                        .map(
                          (value) => DropdownMenuItem<RelationshipType>(
                            value: value,
                            child: Text(_relationshipLabel(value)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isEditable
                        ? (value) {
                            if (value == null) return;
                            onRelationshipTypeChanged(value);
                          }
                        : null,
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
