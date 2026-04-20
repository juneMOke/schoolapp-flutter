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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: relationshipChanged
                        ? successColor.withValues(alpha: 0.35)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.guardianRelationshipLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: relationshipChanged
                            ? successColor
                            : textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, chipConstraints) {
                        final itemsPerRow = chipConstraints.maxWidth < 400
                            ? 4
                            : RelationshipType.values.length;
                        final chipWidth =
                            (chipConstraints.maxWidth -
                                    (itemsPerRow - 1) * 6.0) /
                                itemsPerRow;

                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: RelationshipType.values.map((type) {
                            final isSelected = selectedRelationshipType == type;
                            final activeColor = relationshipChanged
                                ? successColor
                                : primaryColor;

                            return GestureDetector(
                              onTap: isEditable
                                  ? () => onRelationshipTypeChanged(type)
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: chipWidth,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? activeColor.withValues(alpha: 0.1)
                                      : AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? activeColor
                                        : Colors.grey.withValues(alpha: 0.2),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _relationshipIcon(type),
                                      size: 20,
                                      color: isSelected
                                          ? activeColor
                                          : textSecondaryColor,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _relationshipLabel(context, type),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? activeColor
                                            : AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
