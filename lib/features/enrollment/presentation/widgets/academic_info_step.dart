import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/validation_badge.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AcademicInfoStep extends StatefulWidget {
  final EnrollmentSchoolDetail enrollmentDetail;

  const AcademicInfoStep({super.key, required this.enrollmentDetail});

  @override
  State<AcademicInfoStep> createState() => _AcademicInfoStepState();
}

class _AcademicInfoStepState extends State<AcademicInfoStep> {
  // Previous year controllers
  late final TextEditingController _prevYearController;
  late final TextEditingController _prevSchoolController;
  late final TextEditingController _prevCycleController;
  late final TextEditingController _prevLevelController;
  late final TextEditingController _prevRateController;
  late final TextEditingController _prevRankController;
  // Target year controllers
  late final TextEditingController _currYearController;
  late final TextEditingController _targetCycleController;
  late final TextEditingController _targetLevelController;
  late final TextEditingController _targetOptionController;

  @override
  void initState() {
    super.initState();
    final e = widget.enrollmentDetail;
    _prevYearController   = TextEditingController(text: e.previousAcademicYear);
    _prevSchoolController = TextEditingController(text: e.previousSchoolName);
    _prevCycleController  = TextEditingController(text: e.previousSchoolLevelGroup);
    _prevLevelController  = TextEditingController(text: e.previousSchoolLevel);
    _prevRateController   = TextEditingController(text: e.previousRate.toString());
    _prevRankController   = TextEditingController(
      text: e.previousRank?.toString() ?? '',
    );
    _currYearController    = TextEditingController(text: e.academicYearId);
    _targetCycleController = TextEditingController();
    _targetLevelController = TextEditingController();
    _targetOptionController = TextEditingController();
  }

  @override
  void dispose() {
    _prevYearController.dispose();
    _prevSchoolController.dispose();
    _prevCycleController.dispose();
    _prevLevelController.dispose();
    _prevRateController.dispose();
    _prevRankController.dispose();
    _currYearController.dispose();
    _targetCycleController.dispose();
    _targetLevelController.dispose();
    _targetOptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildCard(
          context,
          icon: Icons.school_outlined,
          iconColor: AppTheme.primaryColor,
          title: l10n.previousYear,
          titleColor: AppTheme.primaryColor,
          child: _buildPreviousYearFields(l10n),
        ),
        const SizedBox(height: 20),
        _buildCard(
          context,
          icon: Icons.flag_outlined,
          iconColor: Colors.green[600]!,
          title: l10n.targetYear,
          titleColor: Colors.green[600]!,
          child: _buildTargetYearFields(l10n),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.08),
                  iconColor.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          // ── Contenu ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousYearFields(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final w2 = (constraints.maxWidth - spacing) / 2;
        final w3 = constraints.maxWidth >= 700
            ? (constraints.maxWidth - spacing * 2) / 3
            : w2;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            EditableField(
              width: w2,
              label: l10n.academicYearLabel,
              controller: _prevYearController,
              requiredField: true,
              helpMessage: l10n.academicYearLabelHelp,
            ),
            EditableField(
              width: w2,
              label: l10n.schoolLabel,
              controller: _prevSchoolController,
              requiredField: true,
              helpMessage: l10n.schoolLabelHelp,
            ),
            EditableField(
              width: w2,
              label: l10n.schoolCycle,
              controller: _prevCycleController,
              requiredField: true,
              helpMessage: l10n.schoolCycleHelp,
            ),
            EditableField(
              width: w2,
              label: l10n.schoolLevelLabel,
              controller: _prevLevelController,
              requiredField: true,
              helpMessage: l10n.schoolLevelLabelHelp,
            ),
            EditableField(
              width: w3,
              label: l10n.averageLabel,
              controller: _prevRateController,
              helpMessage: l10n.averageLabelHelp,
            ),
            EditableField(
              width: w3,
              label: l10n.rankingLabel,
              controller: _prevRankController,
              helpMessage: l10n.rankingLabelHelp,
            ),
            SizedBox(
              width: w3,
              child: ValidationBadge(
                isValidated: widget.enrollmentDetail.validatedPreviousYear,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTargetYearFields(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final w = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            EditableField(
              width: w,
              label: l10n.currentAcademicYearLabel,
              controller: _currYearController,
              requiredField: true,
              helpMessage: l10n.currentAcademicYearHelp,
            ),
            EditableField(
              width: w,
              label: l10n.targetCycleLabel,
              controller: _targetCycleController,
              helpMessage: l10n.targetCycleLabelHelp,
            ),
            EditableField(
              width: w,
              label: l10n.targetLevelLabel,
              controller: _targetLevelController,
              helpMessage: l10n.targetLevelLabelHelp,
            ),
            EditableField(
              width: w,
              label: l10n.optionLabel,
              controller: _targetOptionController,
              helpMessage: l10n.optionLabelHelp,
            ),
          ],
        );
      },
    );
  }
}