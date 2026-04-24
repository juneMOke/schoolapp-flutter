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
  late final TextEditingController _prevSchoolController;
  late final TextEditingController _prevRateController;
  late final TextEditingController _prevRankController;

  // Année scolaire, cycle & niveau : valeurs sélectionnées dans les dropdowns
  String? _selectedYear;
  String? _selectedCycle;
  String? _selectedLevel;

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

  // Catalogue des cycles d'éducation
  EducationCyclesCatalog? _cyclesCatalog;
  bool _isCatalogLoading = true;

  bool get _canSave => _stepState.canSave;

  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  late final EnrollmentAcademicInfoBloc _academicInfoBloc;

  // ---------------------------------------------------------------------------
  // Dropdown options
  // ---------------------------------------------------------------------------

  /// Génère les 3 années scolaires les plus récentes selon l'année en cours.
  /// Format : "YYYY-YYYY" (ex. "2025-2026").
  static List<String> _buildYearOptions() {
    final currentYear = DateTime.now().year;
    return List<String>.unmodifiable([
      '${currentYear - 1}-$currentYear',
      '${currentYear - 2}-${currentYear - 1}',
      '${currentYear - 3}-${currentYear - 2}',
    ]);
  }

  /// Résout [rawYear] parmi [options] en comparaison normalisée (ignore espaces
  /// et tirets multiples). Retourne le premier élément si aucune correspondance.
  static String _resolveYear(String? rawYear, List<String> options) {
    if (options.isEmpty) return '';
    if (rawYear == null || rawYear.trim().isEmpty) return options.first;

    final candidate = _normalizeYearKey(rawYear);
    for (final opt in options) {
      if (_normalizeYearKey(opt) == candidate) return opt;
    }
    return options.first;
  }

  static String _normalizeYearKey(String value) =>
      value.replaceAll(RegExp(r'[\s\-–]+'), '-').trim();

  List<String> get _yearOptions => _buildYearOptions();

  List<String> get _cycleOptions {
    final catalog = _cyclesCatalog;
    if (catalog == null) {
      final c = _selectedCycle;
      return c != null && c.isNotEmpty ? [c] : const [];
    }
    return catalog.cycleNames;
  }

  List<String> get _levelOptions {
    final catalog = _cyclesCatalog;
    final cycle = _selectedCycle;
    if (catalog == null || cycle == null || cycle.isEmpty) {
      final l = _selectedLevel;
      return l != null && l.isNotEmpty ? [l] : const [];
    }
    return catalog.yearsForCycle(cycle);
  }

  // ---------------------------------------------------------------------------
  // Normalisation helpers (rate & rank)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _academicInfoBloc = getIt<EnrollmentAcademicInfoBloc>();

    _prevSchoolController = TextEditingController();
    _prevRateController = TextEditingController();
    _prevRankController = TextEditingController();

    _syncFromEnrollmentDetail(widget.enrollmentDetail, resetSnapshot: true);

    _prevSchoolController.addListener(_onFieldChanged);
    _prevRateController.addListener(_onFieldChanged);
    _prevRankController.addListener(_onFieldChanged);

    _loadCyclesCatalog();

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

  Future<void> _loadCyclesCatalog() async {
    try {
      final catalog = await EducationCyclesCatalog.load();
      if (!mounted) return;
      setState(() {
        _cyclesCatalog = catalog;
        _isCatalogLoading = false;
      });
      _syncCycleAndLevelWithCatalog(catalog);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCatalogLoading = false);
    }
  }

  /// Résout cycle & niveau depuis le catalogue une fois chargé.
  /// Si aucune correspondance, sélectionne le premier élément.
  void _syncCycleAndLevelWithCatalog(EducationCyclesCatalog catalog) {
    final rawCycle = _selectedCycle ?? '';
    final rawLevel = _selectedLevel ?? '';

    final resolvedCycle =
        catalog.resolveCycle(rawCycle)?.nom ?? catalog.firstCycle?.nom;

    final resolvedLevel = resolvedCycle == null
        ? null
        : catalog.resolveLevel(resolvedCycle, rawLevel) ??
              catalog.firstLevelForCycle(resolvedCycle);

    if (_selectedCycle != resolvedCycle || _selectedLevel != resolvedLevel) {
      setState(() {
        _selectedCycle = resolvedCycle;
        _selectedLevel = resolvedLevel;
      });
      _recomputeFormState();
    }
  }

  void _syncFromEnrollmentDetail(
    EnrollmentSchoolDetail detail, {
    required bool resetSnapshot,
  }) {
    _isHydratingFromDetail = true;
    try {
      _selectedYear =
          _resolveYear(detail.previousAcademicYear, _buildYearOptions());
      _prevSchoolController.text = detail.previousSchoolName;
      _selectedCycle = detail.previousSchoolLevelGroup.isNotEmpty
          ? detail.previousSchoolLevelGroup
          : null;
      _selectedLevel = detail.previousSchoolLevel.isNotEmpty
          ? detail.previousSchoolLevel
          : null;
      _prevRateController.text = _normalizeRateFromDouble(detail.previousRate);
      _prevRankController.text = _normalizeRankFromInt(detail.previousRank);
      _academicYearId = detail.academicYearId;
      _validatedPreviousYear = detail.validatedPreviousYear;
    } finally {
      _isHydratingFromDetail = false;
    }

    if (resetSnapshot) {
      _initialPrevYear = _selectedYear ?? '';
      _initialPrevSchool = detail.previousSchoolName.trim();
      _initialPrevCycle = detail.previousSchoolLevelGroup.trim();
      _initialPrevLevel = detail.previousSchoolLevel.trim();
      _initialPrevRate = _normalizeRateFromDouble(detail.previousRate);
      _initialPrevRank = _normalizeRankFromInt(detail.previousRank);
      _initialValidatedPreviousYear = detail.validatedPreviousYear;
    }
  }

  void _markCurrentAsSavedSnapshot() {
    _initialPrevYear = _selectedYear ?? '';
    _initialPrevSchool = _prevSchoolController.text.trim();
    _initialPrevCycle = _selectedCycle?.trim() ?? '';
    _initialPrevLevel = _selectedLevel?.trim() ?? '';
    _initialPrevRate = _normalizeRate(_prevRateController.text);
    _initialPrevRank = _normalizeRank(_prevRankController.text);
    _initialValidatedPreviousYear = _validatedPreviousYear;
  }

  @override
  void didUpdateWidget(covariant PreviousAcademicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enrollmentDetail != widget.enrollmentDetail) {
      _syncFromEnrollmentDetail(widget.enrollmentDetail, resetSnapshot: true);
      final catalog = _cyclesCatalog;
      if (catalog != null) {
        _syncCycleAndLevelWithCatalog(catalog);
      }
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
    _prevSchoolController.removeListener(_onFieldChanged);
    _prevRateController.removeListener(_onFieldChanged);
    _prevRankController.removeListener(_onFieldChanged);
    _prevSchoolController.dispose();
    _prevRateController.dispose();
    _prevRankController.dispose();
    _academicInfoBloc.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onFieldChanged() {
    if (_isHydratingFromDetail) return;
    _recomputeFormState();
    if (_showValidationHints && _isValid) {
      setState(() => _showValidationHints = false);
    }
  }

  void _onYearChanged(String? year) {
    setState(() => _selectedYear = year);
    _recomputeFormState();
  }

  void _onCycleChanged(String? cycle) {
    final catalog = _cyclesCatalog;
    final newLevel = catalog?.firstLevelForCycle(cycle ?? '');
    setState(() {
      _selectedCycle = cycle;
      _selectedLevel = newLevel;
    });
    _recomputeFormState();
    if (_showValidationHints && _isValid) {
      setState(() => _showValidationHints = false);
    }
  }

  void _onLevelChanged(String? level) {
    setState(() => _selectedLevel = level);
    _recomputeFormState();
    if (_showValidationHints && _isValid) {
      setState(() => _showValidationHints = false);
    }
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final prevYear = _selectedYear?.trim() ?? '';
    final prevSchool = _prevSchoolController.text.trim();
    final prevCycle = _selectedCycle?.trim() ?? '';
    final prevLevel = _selectedLevel?.trim() ?? '';
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
      if (notifyParent) _emitStepState();
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
    if ((_selectedYear ?? '').isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.academicYearLabel));
    }
    if (_prevSchoolController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.schoolLabel));
    }
    if ((_selectedCycle ?? '').isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.schoolCycle));
    }
    if ((_selectedLevel ?? '').isEmpty) {
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
        previousAcademicYear: _selectedYear ?? '',
        previousSchoolLevelGroup: _selectedCycle ?? '',
        previousSchoolLevel: _selectedLevel ?? '',
        previousRate: double.tryParse(_prevRateController.text.trim()) ?? 0.0,
        previousRank: int.tryParse(_prevRankController.text.trim()),
        validatedPreviousYear: _validatedPreviousYear,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showValidation = _showValidationHints || (_isDirty && !_isValid);

    final year = _selectedYear;
    final cycle = _selectedCycle;
    final level = _selectedLevel;

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
                yearOptions: _yearOptions,
                selectedYear: year,
                onYearChanged: _onYearChanged,
                prevSchoolController: _prevSchoolController,
                cycleOptions: _cycleOptions,
                levelOptions: _levelOptions,
                selectedCycle: cycle,
                selectedLevel: level,
                onCycleChanged: _onCycleChanged,
                onLevelChanged: _onLevelChanged,
                isCatalogLoading: _isCatalogLoading,
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
                    showValidation && (year ?? '').isEmpty
                    ? l10n.requiredFieldError(l10n.academicYearLabel)
                    : null,
                prevSchoolError:
                    showValidation &&
                        _prevSchoolController.text.trim().isEmpty
                    ? l10n.requiredFieldError(l10n.schoolLabel)
                    : null,
                prevCycleError:
                    showValidation && (cycle ?? '').isEmpty
                    ? l10n.requiredFieldError(l10n.schoolCycle)
                    : null,
                prevLevelError:
                    showValidation && (level ?? '').isEmpty
                    ? l10n.requiredFieldError(l10n.schoolLevelLabel)
                    : null,
                prevRateError:
                    showValidation &&
                        (_prevRateController.text.trim().isEmpty ||
                            double.tryParse(
                                  _prevRateController.text.trim(),
                                ) ==
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
                prevYearChanged:
                    (_selectedYear ?? '') != _initialPrevYear,
                prevSchoolChanged:
                    _prevSchoolController.text.trim() != _initialPrevSchool,
                prevCycleChanged:
                    (_selectedCycle?.trim() ?? '') != _initialPrevCycle,
                prevLevelChanged:
                    (_selectedLevel?.trim() ?? '') != _initialPrevLevel,
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
