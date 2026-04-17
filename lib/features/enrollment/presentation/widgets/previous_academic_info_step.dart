import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/enrollment_academic_info_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/academic_info_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousAcademicInfoStep extends StatefulWidget {
  final EnrollmentSchoolDetail enrollmentDetail;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final VoidCallback? onRefreshRequested;
  final bool isEditable;

  const PreviousAcademicInfoStep({
    super.key,
    required this.enrollmentDetail,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.onRefreshRequested,
    this.isEditable = true,
  });

  @override
  State<PreviousAcademicInfoStep> createState() =>
      PreviousAcademicInfoStepState();
}

class PreviousAcademicInfoStepState extends State<PreviousAcademicInfoStep> {
  late final TextEditingController _prevYearController;
  late final TextEditingController _prevSchoolController;
  late final TextEditingController _prevCycleController;
  late final TextEditingController _prevLevelController;
  late final TextEditingController _prevRateController;
  late final TextEditingController _prevRankController;

  late bool _validatedPreviousYear;

  String _academicYearId = '';

  String _initialPrevYear = '';
  String _initialPrevSchool = '';
  String _initialPrevCycle = '';
  String _initialPrevLevel = '';
  String _initialPrevRate = '';
  String _initialPrevRank = '';
  bool _initialValidatedPreviousYear = false;

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;

  bool get _canSave => _stepState.canSave;

  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  late final EnrollmentAcademicInfoBloc _academicInfoBloc;

  String _normalizeRate(String rawValue) {
    final trimmed = rawValue.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return _normalizeRateFromDouble(parsed);
  }

  String _normalizeRateFromDouble(double value) {
    if (value <= 0) return '';
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    var normalized = value.toStringAsFixed(6);
    normalized = normalized.replaceFirst(RegExp(r'0+$'), '');
    normalized = normalized.replaceFirst(RegExp(r'\.$'), '');
    return normalized;
  }

  String _normalizeRank(String rawValue) {
    final trimmed = rawValue.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return parsed.toString();
  }

  String _normalizeRankFromInt(int? value) {
    if (value == null) return '';
    return value.toString();
  }

  bool _isChanged(String currentValue, String initialValue) {
    return currentValue.trim() != initialValue;
  }

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
    _academicInfoBloc = getIt<EnrollmentAcademicInfoBloc>();

    _prevYearController = TextEditingController();
    _prevSchoolController = TextEditingController();
    _prevCycleController = TextEditingController();
    _prevLevelController = TextEditingController();
    _prevRateController = TextEditingController();
    _prevRankController = TextEditingController();

    _syncFromEnrollmentDetail(widget.enrollmentDetail, resetSnapshot: true);

    _prevYearController.addListener(_onFieldChanged);
    _prevSchoolController.addListener(_onFieldChanged);
    _prevCycleController.addListener(_onFieldChanged);
    _prevLevelController.addListener(_onFieldChanged);
    _prevRateController.addListener(_onFieldChanged);
    _prevRankController.addListener(_onFieldChanged);

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

  void _syncFromEnrollmentDetail(
    EnrollmentSchoolDetail detail, {
    required bool resetSnapshot,
  }) {
    _isHydratingFromDetail = true;
    try {
      _prevYearController.text = detail.previousAcademicYear;
      _prevSchoolController.text = detail.previousSchoolName;
      _prevCycleController.text = detail.previousSchoolLevelGroup;
      _prevLevelController.text = detail.previousSchoolLevel;
      _prevRateController.text = _normalizeRateFromDouble(detail.previousRate);
      _prevRankController.text = _normalizeRankFromInt(detail.previousRank);
      _academicYearId = detail.academicYearId;
      _validatedPreviousYear = detail.validatedPreviousYear;
    } finally {
      _isHydratingFromDetail = false;
    }

    if (resetSnapshot) {
      _initialPrevYear = detail.previousAcademicYear.trim();
      _initialPrevSchool = detail.previousSchoolName.trim();
      _initialPrevCycle = detail.previousSchoolLevelGroup.trim();
      _initialPrevLevel = detail.previousSchoolLevel.trim();
      _initialPrevRate = _normalizeRateFromDouble(detail.previousRate);
      _initialPrevRank = _normalizeRankFromInt(detail.previousRank);
      _initialValidatedPreviousYear = detail.validatedPreviousYear;
    }
  }

  void _markCurrentAsSavedSnapshot() {
    _initialPrevYear = _prevYearController.text.trim();
    _initialPrevSchool = _prevSchoolController.text.trim();
    _initialPrevCycle = _prevCycleController.text.trim();
    _initialPrevLevel = _prevLevelController.text.trim();
    _initialPrevRate = _normalizeRate(_prevRateController.text);
    _initialPrevRank = _normalizeRank(_prevRankController.text);
    _initialValidatedPreviousYear = _validatedPreviousYear;
  }

  @override
  void didUpdateWidget(covariant PreviousAcademicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrollmentDetail != widget.enrollmentDetail) {
      _syncFromEnrollmentDetail(widget.enrollmentDetail, resetSnapshot: true);
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
    _prevYearController.removeListener(_onFieldChanged);
    _prevSchoolController.removeListener(_onFieldChanged);
    _prevCycleController.removeListener(_onFieldChanged);
    _prevLevelController.removeListener(_onFieldChanged);
    _prevRateController.removeListener(_onFieldChanged);
    _prevRankController.removeListener(_onFieldChanged);
    _prevYearController.dispose();
    _prevSchoolController.dispose();
    _prevCycleController.dispose();
    _prevLevelController.dispose();
    _prevRateController.dispose();
    _prevRankController.dispose();
    _academicInfoBloc.close();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_isHydratingFromDetail) return;
    _recomputeFormState();
    if (_showValidationHints && _isValid) {
      setState(() => _showValidationHints = false);
    }
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final prevYear = _prevYearController.text.trim();
    final prevSchool = _prevSchoolController.text.trim();
    final prevCycle = _prevCycleController.text.trim();
    final prevLevel = _prevLevelController.text.trim();
    final prevRate = _normalizeRate(_prevRateController.text);
    final prevRank = _normalizeRank(_prevRankController.text);
    final parsedRate = double.tryParse(prevRate);
    final parsedRank = int.tryParse(prevRank);

    final validNow =
        prevYear.isNotEmpty &&
        prevSchool.isNotEmpty &&
        prevCycle.isNotEmpty &&
        prevLevel.isNotEmpty &&
        prevRate.isNotEmpty &&
        parsedRate != null &&
        prevRank.isNotEmpty &&
        parsedRank != null;

    final dirtyNow =
        prevYear != _initialPrevYear ||
        prevSchool != _initialPrevSchool ||
        prevCycle != _initialPrevCycle ||
        prevLevel != _initialPrevLevel ||
        prevRate != _initialPrevRate ||
        prevRank != _initialPrevRank ||
        _validatedPreviousYear != _initialValidatedPreviousYear;

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
    if (_prevYearController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.academicYearLabel));
    }
    if (_prevSchoolController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.schoolLabel));
    }
    if (_prevCycleController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.schoolCycle));
    }
    if (_prevLevelController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.schoolLevelLabel));
    }
    if (_prevRateController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.averageLabel));
    } else if (double.tryParse(_prevRateController.text.trim()) == null) {
      errors.add(l10n.invalidNumberFieldError(l10n.averageLabel));
    }
    if (_prevRankController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.rankingLabel));
    } else if (int.tryParse(_prevRankController.text.trim()) == null) {
      errors.add(l10n.invalidNumberFieldError(l10n.rankingLabel));
    }
    return errors;
  }

  void _onSave() {
    if (!widget.isEditable) return;
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

    _academicInfoBloc.add(
      EnrollmentAcademicInfoUpdateRequested(
        enrollmentId: widget.enrollmentId,
        academicYearId: _academicYearId,
        previousSchoolName: _prevSchoolController.text.trim(),
        previousAcademicYear: _prevYearController.text.trim(),
        previousSchoolLevelGroup: _prevCycleController.text.trim(),
        previousSchoolLevel: _prevLevelController.text.trim(),
        previousRate: double.tryParse(_prevRateController.text.trim()) ?? 0.0,
        previousRank: int.tryParse(_prevRankController.text.trim()),
        validatedPreviousYear: _validatedPreviousYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showValidation = _showValidationHints || (_isDirty && !_isValid);

    return BlocProvider<EnrollmentAcademicInfoBloc>.value(
      value: _academicInfoBloc,
      child:
          BlocConsumer<EnrollmentAcademicInfoBloc, EnrollmentAcademicInfoState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              _onSavingChanged(
                state.status == EnrollmentAcademicInfoStatus.loading,
              );

              if (state.status == EnrollmentAcademicInfoStatus.success) {
                _markCurrentAsSavedSnapshot();
                _recomputeFormState();
                _onSavingChanged(false);
                if (_showValidationHints) {
                  setState(() => _showValidationHints = false);
                }
                widget.onRefreshRequested?.call();
                AppSnackBar.showSuccess(context, l10n.academicInfoSaveSuccess);
              } else if (state.status == EnrollmentAcademicInfoStatus.failure) {
                _onSavingChanged(false);
                AppSnackBar.showError(
                  context,
                  l10n.academicInfoSaveError(state.errorMessage ?? ''),
                );
              }
            },
            builder: (context, state) {
              final isLoading =
                  state.status == EnrollmentAcademicInfoStatus.loading;
              return PreviousAcademicInfoStepBody(
                prevYearController: _prevYearController,
                prevSchoolController: _prevSchoolController,
                prevCycleController: _prevCycleController,
                prevLevelController: _prevLevelController,
                prevRateController: _prevRateController,
                prevRankController: _prevRankController,
                validatedPreviousYear: _validatedPreviousYear,
                showValidation: showValidation,
                isLoading: isLoading,
                canSave: _canSave,
                showInlineSaveButton: widget.showInlineSaveButton,
                onSave: _onSave,
                isEditable: widget.isEditable,
                onValidatedChanged: (value) {
                  setState(() => _validatedPreviousYear = value);
                  _recomputeFormState();
                },
                prevYearError:
                    showValidation && _prevYearController.text.trim().isEmpty
                    ? l10n.requiredFieldError(l10n.academicYearLabel)
                    : null,
                prevSchoolError:
                    showValidation && _prevSchoolController.text.trim().isEmpty
                    ? l10n.requiredFieldError(l10n.schoolLabel)
                    : null,
                prevCycleError:
                    showValidation && _prevCycleController.text.trim().isEmpty
                    ? l10n.requiredFieldError(l10n.schoolCycle)
                    : null,
                prevLevelError:
                    showValidation && _prevLevelController.text.trim().isEmpty
                    ? l10n.requiredFieldError(l10n.schoolLevelLabel)
                    : null,
                prevRateError:
                    showValidation &&
                        (_prevRateController.text.trim().isEmpty ||
                            double.tryParse(_prevRateController.text.trim()) ==
                                null)
                    ? (_prevRateController.text.trim().isEmpty
                          ? l10n.requiredFieldError(l10n.averageLabel)
                          : l10n.invalidNumberFieldError(l10n.averageLabel))
                    : null,
                prevRankError:
                    showValidation &&
                        (_prevRankController.text.trim().isEmpty ||
                            int.tryParse(_prevRankController.text.trim()) ==
                                null)
                    ? (_prevRankController.text.trim().isEmpty
                          ? l10n.requiredFieldError(l10n.rankingLabel)
                          : l10n.invalidNumberFieldError(l10n.rankingLabel))
                    : null,
                prevYearChanged: _isChanged(
                  _prevYearController.text,
                  _initialPrevYear,
                ),
                prevSchoolChanged: _isChanged(
                  _prevSchoolController.text,
                  _initialPrevSchool,
                ),
                prevCycleChanged: _isChanged(
                  _prevCycleController.text,
                  _initialPrevCycle,
                ),
                prevLevelChanged: _isChanged(
                  _prevLevelController.text,
                  _initialPrevLevel,
                ),
                prevRateChanged:
                    _normalizeRate(_prevRateController.text) !=
                    _initialPrevRate,
                prevRankChanged:
                    _normalizeRank(_prevRankController.text) !=
                    _initialPrevRank,
                validatedPreviousYearChanged:
                    _validatedPreviousYear != _initialValidatedPreviousYear,
              );
            },
          ),
    );
  }
}
