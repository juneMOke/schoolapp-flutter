import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/academic_info_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TargetAcademicInfoStep extends StatefulWidget {
  final StudentDetail studentDetail;
  final String studentId;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final int? flowStepIndex;

  const TargetAcademicInfoStep({
    super.key,
    required this.studentDetail,
    required this.studentId,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
  });

  @override
  State<TargetAcademicInfoStep> createState() => TargetAcademicInfoStepState();
}

class TargetAcademicInfoStepState extends State<TargetAcademicInfoStep> {
  late final TextEditingController _currYearController;
  late final TextEditingController _targetOptionController;

  late String _selectedSchoolLevelGroupId;
  late String _selectedSchoolLevelId;
  bool _bootstrapDefaultsApplied = false;

  String _initialSchoolLevelGroupId = '';
  String _initialSchoolLevelId = '';

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;

  bool get _canSave => _stepState.canSave;

  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  late final StudentBloc _studentBloc;

  void submitForm() => _onSave();

  void _emitStepState() {
    final flowStepIndex = widget.flowStepIndex;
    if (flowStepIndex != null && mounted) {
      context.read<EnrollmentStepperFlowBloc>().add(
        EnrollmentStepperStepStateReported(
          step: flowStepIndex,
          stepState: _stepState,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _studentBloc = getIt<StudentBloc>();

    _currYearController = TextEditingController();
    _targetOptionController = TextEditingController();

    _syncFromStudentDetail(widget.studentDetail, resetSnapshot: true);

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

  void _syncFromStudentDetail(
    StudentDetail detail, {
    required bool resetSnapshot,
  }) {
    _selectedSchoolLevelGroupId = detail.schoolLevelGroup.id;
    _selectedSchoolLevelId = detail.schoolLevel.id;

    if (resetSnapshot) {
      _initialSchoolLevelGroupId = detail.schoolLevelGroup.id;
      _initialSchoolLevelId = detail.schoolLevel.id;
    }
  }

  void _markCurrentAsSavedSnapshot() {
    _initialSchoolLevelGroupId = _selectedSchoolLevelGroupId;
    _initialSchoolLevelId = _selectedSchoolLevelId;
  }

  @override
  void didUpdateWidget(covariant TargetAcademicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentDetail != widget.studentDetail) {
      _syncFromStudentDetail(widget.studentDetail, resetSnapshot: true);
      _bootstrapDefaultsApplied = false;
      _showValidationHints = false;
      _isSaving = false;
      _recomputeFormState(notifyParent: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _emitStepState();
      });
    }
  }

  @override
  void dispose() {
    _currYearController.dispose();
    _targetOptionController.dispose();
    _studentBloc.close();
    super.dispose();
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final currYear = _currYearController.text.trim();

    final validNow =
        currYear.isNotEmpty &&
        _selectedSchoolLevelGroupId.isNotEmpty &&
        _selectedSchoolLevelId.isNotEmpty;

    final dirtyNow =
        _selectedSchoolLevelGroupId != _initialSchoolLevelGroupId ||
        _selectedSchoolLevelId != _initialSchoolLevelId;

    if (_isValid != validNow || _isDirty != dirtyNow) {
      setState(() {
        _isValid = validNow;
        _isDirty = dirtyNow;
      });
      if (notifyParent) {
        _emitStepState();
      }
    } else if (notifyParent) {
      _emitStepState();
    }
  }

  void _onSavingChanged(bool saving) {
    if (_isSaving == saving) return;
    _isSaving = saving;
    _emitStepState();
  }

  List<String> _buildValidationErrors(AppLocalizations l10n) {
    final errors = <String>[];
    if (_currYearController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.currentAcademicYearLabel));
    }
    if (_selectedSchoolLevelGroupId.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.targetCycleLabel));
    }
    if (_selectedSchoolLevelId.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.targetLevelLabel));
    }
    return errors;
  }

  void _onSave() {
    final l10n = AppLocalizations.of(context)!;
    if (!_isValid) {
      final reasons = _buildValidationErrors(l10n);
      setState(() => _showValidationHints = true);
      AppSnackBar.showValidationErrors(
        context,
        title: l10n.academicInfoValidationReasonsTitle,
        reasons: reasons,
      );
      return;
    }
    if (!_isDirty) return;

    _studentBloc.add(
      StudentAcademicInfoUpdateRequested(
        studentId: widget.studentId,
        schoolLevelId: _selectedSchoolLevelId,
        schoolLevelGroupId: _selectedSchoolLevelGroupId,
      ),
    );
  }

  void _applyBootstrapDefaults(Bootstrap bootstrap) {
    bool bootstrapChanged = false;
    final previousCurrentYear = _currYearController.text;
    _currYearController.text = bootstrap.currentAcademicYear.name;
    if (previousCurrentYear != _currYearController.text) {
      bootstrapChanged = true;
    }
    if (_bootstrapDefaultsApplied) return;

    final groupBundles = bootstrap.schoolLevelGroups;
    final selectedGroupBundle = groupBundles
        .where((g) => g.schoolLevelGroup.id == _selectedSchoolLevelGroupId)
        .firstOrNull;

    if (selectedGroupBundle == null && groupBundles.isNotEmpty) {
      _selectedSchoolLevelGroupId = groupBundles.first.schoolLevelGroup.id;
      _initialSchoolLevelGroupId = _selectedSchoolLevelGroupId;
      bootstrapChanged = true;
    }

    final resolvedGroupBundle = groupBundles
        .where((g) => g.schoolLevelGroup.id == _selectedSchoolLevelGroupId)
        .firstOrNull;
    if (resolvedGroupBundle != null &&
        resolvedGroupBundle.schoolLevels.every(
          (l) => l.schoolLevel.id != _selectedSchoolLevelId,
        )) {
      _selectedSchoolLevelId = resolvedGroupBundle.schoolLevels.isNotEmpty
          ? resolvedGroupBundle.schoolLevels.first.schoolLevel.id
          : '';
      _initialSchoolLevelId = _selectedSchoolLevelId;
      bootstrapChanged = true;
    }

    _bootstrapDefaultsApplied = true;

    if (bootstrapChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _recomputeFormState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showValidation = _showValidationHints || (_isDirty && !_isValid);

    return BlocProvider<StudentBloc>.value(
      value: _studentBloc,
      child: BlocConsumer<StudentBloc, StudentState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status || prev.operation != curr.operation,
        listener: (context, state) {
          if (state.operation != StudentUpdateOperation.academicInfo) {
            return;
          }

          _onSavingChanged(state.status == StudentUpdateStatus.loading);

          if (state.status == StudentUpdateStatus.success) {
            _markCurrentAsSavedSnapshot();
            _recomputeFormState();
            _onSavingChanged(false);
            if (_showValidationHints) {
              setState(() => _showValidationHints = false);
            }
            context.read<EnrollmentBloc>().add(
              EnrollmentDetailRequested(
                enrollmentId: widget.enrollmentId,
                silent: true,
              ),
            );
            AppSnackBar.showSuccess(context, l10n.academicInfoSaveSuccess);
          } else if (state.status == StudentUpdateStatus.failure) {
            _onSavingChanged(false);
            AppSnackBar.showError(
              context,
              l10n.academicInfoSaveError(state.errorMessage ?? ''),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state.status == StudentUpdateStatus.loading &&
              state.operation == StudentUpdateOperation.academicInfo;

          return BlocBuilder<BootstrapBloc, BootstrapState>(
            builder: (context, bootstrapState) {
              final bootstrap = bootstrapState.bootstrap;
              if (bootstrap != null) {
                _applyBootstrapDefaults(bootstrap);
              }

              return AcademicInfoStepBody(
                bootstrap: bootstrap,
                currYearController: _currYearController,
                targetOptionController: _targetOptionController,
                selectedSchoolLevelGroupId: _selectedSchoolLevelGroupId,
                selectedSchoolLevelId: _selectedSchoolLevelId,
                showValidation: showValidation,
                isLoading: isLoading,
                canSave: _canSave,
                showInlineSaveButton: widget.showInlineSaveButton,
                showPreviousSection: false,
                showTargetSection: true,
                onSave: _onSave,
                onGroupChanged: (groupId, firstLevelId) {
                  setState(() {
                    _selectedSchoolLevelGroupId = groupId;
                    _selectedSchoolLevelId = firstLevelId;
                  });
                  _recomputeFormState();
                },
                onLevelChanged: (levelId) {
                  setState(() => _selectedSchoolLevelId = levelId);
                  _recomputeFormState();
                },
                groupError:
                    showValidation && _selectedSchoolLevelGroupId.isEmpty
                    ? l10n.requiredFieldError(l10n.targetCycleLabel)
                    : null,
                levelError: showValidation && _selectedSchoolLevelId.isEmpty
                    ? l10n.requiredFieldError(l10n.targetLevelLabel)
                    : null,
                groupChanged:
                    _selectedSchoolLevelGroupId != _initialSchoolLevelGroupId,
                levelChanged: _selectedSchoolLevelId != _initialSchoolLevelId,
              );
            },
          );
        },
      ),
    );
  }
}
