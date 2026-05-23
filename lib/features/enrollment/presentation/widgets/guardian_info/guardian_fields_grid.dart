import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_email_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_phone_field.dart';
import 'package:school_app_flutter/core/components/fields/editable_field.dart';
import 'package:school_app_flutter/core/components/labels/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
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
  final bool isPrimary;
  final ValueChanged<bool?>? onPrimaryChanged;

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
    this.isPrimary = false,
    this.onPrimaryChanged,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final width = constraints.maxWidth >= 640
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: AppSpacing.md,
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
            GuardianPhoneField(
              width: width,
              label: l10n.phoneNumberLabel,
              helpMessage: l10n.phoneNumberHelp,
              controller: phoneController,
              requiredField: true,
              isChanged: phoneChanged,
              readOnly: !isEditable,
            ),
            GuardianEmailField(
              width: width,
              label: l10n.emailLabel,
              helpMessage: l10n.emailLabelHelp,
              controller: emailController,
              requiredField: false,
              isChanged: emailChanged,
              readOnly: !isEditable,
              trailingLabel: l10n.guardianEmailOptionalInline,
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormFieldLabel(
                    label: l10n.guardianRelationshipLabel,
                    requiredField: true,
                    helpMessage: '',
                    labelColor: relationshipChanged ? AppColors.success : null,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<RelationshipType>(
                    initialValue: selectedRelationshipType,
                    items: RelationshipType.values
                        .map(
                          (type) => DropdownMenuItem<RelationshipType>(
                            value: type,
                            child: Text(_relationshipLabel(context, type)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isEditable
                        ? (value) {
                            if (value == null) return;
                            onRelationshipTypeChanged(value);
                          }
                        : null,
                    decoration: buildInputDecoration(
                      hintText: l10n.guardianRelationshipLabel,
                      isChanged: relationshipChanged,
                      prefixIcon: const Icon(
                        Icons.family_restroom_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: width,
              child: Row(
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
      },
    );
  }
}
