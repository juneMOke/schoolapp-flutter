import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/personal_info_step_body.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';

class PersonalInfoStep extends StatefulWidget {
  final StudentDetail studentDetail;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final VoidCallback? onRefreshRequested;
  final bool isEditable;
  final EnrollmentDetailIntent detailIntent;
  final EnrollmentDetailPolicy detailPolicy;

  const PersonalInfoStep({
    super.key,
    required this.studentDetail,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.onRefreshRequested,
    this.isEditable = true,
    required this.detailIntent,
    required this.detailPolicy,
  });

  @override
  State<PersonalInfoStep> createState() => PersonalInfoStepState();
}

class PersonalInfoStepState extends State<PersonalInfoStep> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _nationalityController;
  late final StudentBloc _studentBloc;

  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialSurname = '';
  String _initialBirthPlace = '';
  String _initialNationality = '';
  Gender? _initialGender;
  DateTime? _initialDate;

  late Gender _selectedGender;
  DateTime? _selectedDate;
  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;

  bool get canSubmit => _isValid && _isDirty;
  bool get isDirty => _isDirty;
  bool get isValid => _isValid;
  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  void _emitStepState() {
    final state = _stepState;
    final flowStepIndex = widget.flowStepIndex;
    if (flowStepIndex != null && mounted) {
      context.read<EnrollmentStepperFlowBloc>().add(
        EnrollmentStepperStepStateReported(
          step: flowStepIndex,
          stepState: state,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _studentBloc = getIt<StudentBloc>();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _surnameController = TextEditingController();
    _birthPlaceController = TextEditingController();
    _nationalityController = TextEditingController();

    _initializeFromStudent(widget.studentDetail);

    _firstNameController.addListener(_onTextFieldChanged);
    _lastNameController.addListener(_onTextFieldChanged);
    _surnameController.addListener(_onTextFieldChanged);
    _birthPlaceController.addListener(_onTextFieldChanged);
    _nationalityController.addListener(_onTextFieldChanged);

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

  void _onTextFieldChanged() {
    if (_isHydratingFromDetail) return;
    _recomputeFormState();
    if (_showValidationHints) {
      setState(() {
        if (_isValid) {
          _showValidationHints = false;
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PersonalInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentDetail != widget.studentDetail) {
      _initializeFromStudent(widget.studentDetail);
      _isSaving = false;
      _recomputeFormState(notifyParent: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _emitStepState();
      });
    }
  }

  void _initializeFromStudent(StudentDetail student) {
    _isHydratingFromDetail = true;
    try {
      _firstNameController.text = student.firstName;
      _lastNameController.text = student.lastName;
      _surnameController.text = student.surname;
      _birthPlaceController.text = student.birthPlace;
      _nationalityController.text = student.nationality;
      _selectedGender = student.gender;
      _selectedDate = _formatSelectedDate(student);
    } finally {
      _isHydratingFromDetail = false;
    }

    _initialFirstName = student.firstName.trim();
    _initialLastName = student.lastName.trim();
    _initialSurname = student.surname.trim();
    _initialBirthPlace = student.birthPlace.trim();
    _initialNationality = student.nationality.trim();
    _initialGender = student.gender;
    _initialDate = _formatSelectedDate(student);
  }

  void _markCurrentAsSavedSnapshot() {
    _initialFirstName = _firstNameController.text.trim();
    _initialLastName = _lastNameController.text.trim();
    _initialSurname = _surnameController.text.trim();
    _initialBirthPlace = _birthPlaceController.text.trim();
    _initialNationality = _nationalityController.text.trim();
    _initialGender = _selectedGender;
    _initialDate = _selectedDate;
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final validNow =
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _surnameController.text.trim().isNotEmpty &&
        _birthPlaceController.text.trim().isNotEmpty &&
        _nationalityController.text.trim().isNotEmpty &&
        _selectedDate != null;

    final dirtyNow =
        _firstNameController.text.trim() != _initialFirstName ||
        _lastNameController.text.trim() != _initialLastName ||
        _surnameController.text.trim() != _initialSurname ||
        _birthPlaceController.text.trim() != _initialBirthPlace ||
        _nationalityController.text.trim() != _initialNationality ||
        _selectedGender != _initialGender ||
        _selectedDate != _initialDate;

    if (_isValid != validNow) {
      _isValid = validNow;
    }
    if (_isDirty != dirtyNow) {
      _isDirty = dirtyNow;
    }
    if (notifyParent) {
      _emitStepState();
    }
  }

  void _onSavingChanged(bool saving) {
    if (_isSaving == saving) return;
    _isSaving = saving;
    _emitStepState();
  }

  DateTime? _formatSelectedDate(StudentDetail student) {
    try {
      final parts = student.dateOfBirth.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    return null;
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onTextFieldChanged);
    _lastNameController.removeListener(_onTextFieldChanged);
    _surnameController.removeListener(_onTextFieldChanged);
    _birthPlaceController.removeListener(_onTextFieldChanged);
    _nationalityController.removeListener(_onTextFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _birthPlaceController.dispose();
    _nationalityController.dispose();
    _studentBloc.close();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 10),
      firstDate: DateTime(1990),
      lastDate: now,
      locale: const Locale('fr'),
      helpText: l10n.selectDateOfBirthHelpText,
      cancelText: l10n.cancel,
      confirmText: l10n.confirm,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _recomputeFormState();
      if (_showValidationHints && _isValid) {
        setState(() => _showValidationHints = false);
      }
    }
  }

  List<String> _buildValidationErrors(AppLocalizations l10n) {
    final errors = <String>[];
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final surname = _surnameController.text.trim();
    final birthPlace = _birthPlaceController.text.trim();
    final nationality = _nationalityController.text.trim();

    if (firstName.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.firstName));
    }
    if (lastName.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.lastName));
    }
    if (surname.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.surname));
    }
    if (_selectedDate == null) {
      errors.add(l10n.requiredFieldError(l10n.dateOfBirth));
    }
    if (birthPlace.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.birthPlace));
    }
    if (nationality.isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.nationality));
    }

    return errors;
  }

  String? _fieldErrorFor(
    String value,
    String fieldLabel,
    AppLocalizations l10n,
    bool showValidation,
  ) {
    if (!showValidation || value.trim().isNotEmpty) {
      return null;
    }
    return l10n.requiredFieldError(fieldLabel);
  }

  String? _dateErrorFor(AppLocalizations l10n, bool showValidation) {
    if (!showValidation || _selectedDate != null) {
      return null;
    }
    return l10n.requiredFieldError(l10n.dateOfBirth);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  String _toIsoDate(DateTime? date) {
    if (date == null) return widget.studentDetail.dateOfBirth;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void submitForm() {
    _onSave(context);
  }

  void _onSave(BuildContext context) {
    if (!widget.isEditable) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_isValid) {
      final reasons = _buildValidationErrors(l10n);
      setState(() => _showValidationHints = true);
      AppSnackBar.showValidationErrors(
        context,
        title: l10n.personalInfoValidationReasonsTitle,
        reasons: reasons,
      );
      return;
    }
    if (!_isDirty) return;

    widget.detailPolicy.savePersonalInfo(
      enrollmentBloc: context.read<EnrollmentBloc>(),
      studentBloc: _studentBloc,
      intent: widget.detailIntent,
      currentStudent: widget.studentDetail,
      payload: EnrollmentPersonalInfoPayload(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        dateOfBirth: _toIsoDate(_selectedDate),
        gender: _selectedGender.name.toUpperCase(),
        birthPlace: _birthPlaceController.text.trim(),
        nationality: _nationalityController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showValidation = _showValidationHints || (_isDirty && !_isValid);

    return BlocProvider<StudentBloc>.value(
      value: _studentBloc,
      child: BlocListener<EnrollmentBloc, EnrollmentState>(
        listenWhen: (previous, current) =>
            previous.createStatus != current.createStatus,
        listener: (context, state) {
          _onSavingChanged(state.createStatus == EnrollmentLoadStatus.loading);

          if (state.createStatus == EnrollmentLoadStatus.success) {
            _markCurrentAsSavedSnapshot();
            _recomputeFormState();
            _onSavingChanged(false);
            if (_showValidationHints) {
              setState(() => _showValidationHints = false);
            }
            AppSnackBar.showSuccess(context, l10n.personalInfoSaveSuccess);
            return;
          }

          if (state.createStatus == EnrollmentLoadStatus.failure) {
            _onSavingChanged(false);
            AppSnackBar.showError(
              context,
              l10n.personalInfoSaveError(state.errorMessage ?? ''),
            );
          }
        },
        child: PersonalInfoStepBody(
          studentDetail: widget.studentDetail,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          surnameController: _surnameController,
          birthPlaceController: _birthPlaceController,
          nationalityController: _nationalityController,
          selectedGender: _selectedGender,
          selectedDate: _selectedDate,
          onGenderChanged: (g) {
            if (g != null) {
              setState(() => _selectedGender = g);
              _recomputeFormState();
            }
          },
          onPickDate: () => _pickDate(context),
          onSave: _onSave,
          formatDate: _formatDate,
          enrollmentId: widget.enrollmentId,
          showInlineSaveButton: widget.showInlineSaveButton,
          canSave: canSubmit,
          isEditable: widget.isEditable,
          firstNameError: _fieldErrorFor(
            _firstNameController.text,
            l10n.firstName,
            l10n,
            showValidation,
          ),
          lastNameError: _fieldErrorFor(
            _lastNameController.text,
            l10n.lastName,
            l10n,
            showValidation,
          ),
          surnameError: _fieldErrorFor(
            _surnameController.text,
            l10n.surname,
            l10n,
            showValidation,
          ),
          birthPlaceError: _fieldErrorFor(
            _birthPlaceController.text,
            l10n.birthPlace,
            l10n,
            showValidation,
          ),
          nationalityError: _fieldErrorFor(
            _nationalityController.text,
            l10n.nationality,
            l10n,
            showValidation,
          ),
          dateOfBirthError: _dateErrorFor(l10n, showValidation),
          onSavingChanged: _onSavingChanged,
          onSaveSuccess: () {
            _markCurrentAsSavedSnapshot();
            _recomputeFormState();
            _onSavingChanged(false);
            widget.onRefreshRequested?.call();
            if (_showValidationHints) {
              setState(() => _showValidationHints = false);
            }
          },
          onRefreshRequested: widget.onRefreshRequested,
        ),
      ),
    );
  }
}
