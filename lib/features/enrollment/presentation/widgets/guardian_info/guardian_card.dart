import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/relationship_chip.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianCard extends StatefulWidget {
  final ParentSummary parent;
  final bool isPrimary;
  final int number;

  const GuardianCard({
    super.key,
    required this.parent,
    required this.isPrimary,
    required this.number,
  });

  @override
  State<GuardianCard> createState() => _GuardianCardState();
}

class _GuardianCardState extends State<GuardianCard> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _idController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final p = widget.parent;
    _firstNameController = TextEditingController(text: p.firstName);
    _lastNameController  = TextEditingController(text: p.lastName);
    _surnameController   = TextEditingController(text: p.surname ?? '');
    _idController        = TextEditingController(text: p.identificationNumber);
    _phoneController     = TextEditingController(text: p.phoneNumber);
    _emailController     = TextEditingController(text: p.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _getInitials() {
    final f = widget.parent.firstName.isNotEmpty ? widget.parent.firstName[0] : '';
    final l = widget.parent.lastName.isNotEmpty  ? widget.parent.lastName[0]  : '';
    return '$f$l'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPrimary = widget.isPrimary;
    final parent = widget.parent;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? AppTheme.primaryColor.withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
          width: isPrimary ? 1.5 : 1,
        ),
      ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête carte ──────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? AppTheme.primaryColor
                          : Colors.grey[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPrimary
                          ? l10n.primaryGuardian
                          : l10n.guardianNumber(widget.number),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  RelationshipChip(
                    relationshipType: parent.relationshipType,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Avatar + nom ────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${parent.firstName} ${parent.lastName}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Champs éditables ────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 16.0;
                  final w = constraints.maxWidth >= 640
                      ? (constraints.maxWidth - spacing) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 14,
                    children: [
                      EditableField(
                        width: w,
                        label: l10n.firstName,
                        controller: _firstNameController,
                        requiredField: true,
                        helpMessage: l10n.firstNameHelp,
                      ),
                      EditableField(
                        width: w,
                        label: l10n.lastName,
                        controller: _lastNameController,
                        requiredField: true,
                        helpMessage: l10n.lastNameHelp,
                      ),
                      EditableField(
                        width: w,
                        label: l10n.surname,
                        controller: _surnameController,
                        helpMessage: l10n.surnameHelp,
                      ),
                      EditableField(
                        width: w,
                        label: l10n.identificationNumberLabel,
                        controller: _idController,
                        requiredField: true,
                        helpMessage: l10n.identificationNumberHelp,
                      ),
                      EditableField(
                        width: w,
                        label: l10n.phoneNumberLabel,
                        controller: _phoneController,
                        requiredField: true,
                        helpMessage: l10n.phoneNumberHelp,
                      ),
                      EditableField(
                        width: w,
                        label: l10n.emailLabel,
                        controller: _emailController,
                        requiredField: true,
                        helpMessage: l10n.emailLabelHelp,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
    );
  }
}