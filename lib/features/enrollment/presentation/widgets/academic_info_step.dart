import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/academic_info_widgets.dart';
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
  late final TextEditingController _targetOptionController;
  late bool _validatedPreviousYear;
  late String _selectedSchoolLevelGroupId;
  late String _selectedSchoolLevelId;
  bool _bootstrapDefaultsApplied = false;

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
    _targetOptionController = TextEditingController();
    _validatedPreviousYear = e.validatedPreviousYear;
    _selectedSchoolLevelGroupId = e.schoolLevelGroupId;
    _selectedSchoolLevelId = e.schoolLevelId;
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
    _targetOptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BootstrapBloc, BootstrapState>(
      builder: (context, bootstrapState) {
        final bootstrap = bootstrapState.bootstrap;
        if (bootstrap != null) {
          _applyBootstrapDefaults(bootstrap);
        }

        return Column(
          children: [
            _buildCard(
              context,
              icon: Icons.school_outlined,
              iconColor: AppTheme.primaryColor,
              title: l10n.previousYear,
              titleColor: AppTheme.primaryColor,
              child: PreviousYearFields(
                l10n: l10n,
                prevYearController: _prevYearController,
                prevSchoolController: _prevSchoolController,
                prevCycleController: _prevCycleController,
                prevLevelController: _prevLevelController,
                prevRateController: _prevRateController,
                prevRankController: _prevRankController,
                validatedPreviousYear: _validatedPreviousYear,
                onValidatedChanged: (value) {
                  setState(() => _validatedPreviousYear = value);
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildCard(
              context,
              icon: Icons.flag_outlined,
              iconColor: Colors.green[600]!,
              title: l10n.targetYear,
              titleColor: Colors.green[600]!,
              child: TargetYearFields(
                l10n: l10n,
                bootstrap: bootstrap,
                currYearController: _currYearController,
                targetOptionController: _targetOptionController,
                selectedSchoolLevelGroupId: _selectedSchoolLevelGroupId,
                selectedSchoolLevelId: _selectedSchoolLevelId,
                onGroupChanged: (groupId, firstLevelId) {
                  setState(() {
                    _selectedSchoolLevelGroupId = groupId;
                    _selectedSchoolLevelId = firstLevelId;
                  });
                },
                onLevelChanged: (levelId) {
                  setState(() => _selectedSchoolLevelId = levelId);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _applyBootstrapDefaults(Bootstrap bootstrap) {
    _currYearController.text = bootstrap.currentAcademicYear.name;
    if (_bootstrapDefaultsApplied) return;

    final groupBundles = bootstrap.schoolLevelGroups;
    final selectedGroupBundle = groupBundles
        .where((g) => g.schoolLevelGroup.id == _selectedSchoolLevelGroupId)
        .firstOrNull;

    if (selectedGroupBundle == null && groupBundles.isNotEmpty) {
      _selectedSchoolLevelGroupId = groupBundles.first.schoolLevelGroup.id;
    }

    final resolvedGroupBundle = groupBundles
        .where((g) => g.schoolLevelGroup.id == _selectedSchoolLevelGroupId)
        .firstOrNull;
    if (resolvedGroupBundle != null &&
        resolvedGroupBundle.schoolLevels
            .every((l) => l.schoolLevel.id != _selectedSchoolLevelId)) {
      _selectedSchoolLevelId = resolvedGroupBundle.schoolLevels.isNotEmpty
          ? resolvedGroupBundle.schoolLevels.first.schoolLevel.id
          : '';
    }

    _bootstrapDefaultsApplied = true;
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
}