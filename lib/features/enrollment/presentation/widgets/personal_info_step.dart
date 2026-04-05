import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/personal_info_step_body.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PersonalInfoStep extends StatefulWidget {
  final StudentDetail studentDetail;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final ValueChanged<bool>? onDirtyChanged;
  final ValueChanged<bool>? onValidityChanged;
  final ValueChanged<bool>? onSavingChanged;
  final VoidCallback? onSaveSuccess;

  const PersonalInfoStep({
    super.key,
    required this.studentDetail,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.onDirtyChanged,
    this.onValidityChanged,
    this.onSavingChanged,
    this.onSaveSuccess,
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

  bool get canSubmit => _isValid && _isDirty;
  bool get isDirty => _isDirty;
  bool get isValid => _isValid;

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

    _firstNameController.addListener(_recomputeFormState);
    _lastNameController.addListener(_recomputeFormState);
    _surnameController.addListener(_recomputeFormState);
    _birthPlaceController.addListener(_recomputeFormState);
    _nationalityController.addListener(_recomputeFormState);

    _recomputeFormState(notifyParent: false);
    _notifyParentFormState();
  }

  @override
  void didUpdateWidget(covariant PersonalInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentDetail != widget.studentDetail) {
      _initializeFromStudent(widget.studentDetail);
      _recomputeFormState(notifyParent: false);
      _notifyParentFormState();
    }
  }

  void _notifyParentFormState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onValidityChanged?.call(_isValid);
      widget.onDirtyChanged?.call(_isDirty);
    });
  }

  void _initializeFromStudent(StudentDetail student) {
    _firstNameController.text = student.firstName;
    _lastNameController.text = student.lastName;
    _surnameController.text = student.surname;
    _birthPlaceController.text = student.birthPlace;
    _nationalityController.text = student.nationality;
    _selectedGender = student.gender;
    _selectedDate = _formatSelectedDate(student);

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
      if (notifyParent) {
        widget.onValidityChanged?.call(_isValid);
      }
    }
    if (_isDirty != dirtyNow) {
      _isDirty = dirtyNow;
      if (notifyParent) {
        widget.onDirtyChanged?.call(_isDirty);
      }
    }
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
    _firstNameController.removeListener(_recomputeFormState);
    _lastNameController.removeListener(_recomputeFormState);
    _surnameController.removeListener(_recomputeFormState);
    _birthPlaceController.removeListener(_recomputeFormState);
    _nationalityController.removeListener(_recomputeFormState);
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
    }
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
    final l10n = AppLocalizations.of(context)!;
    if (!_isValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.validatePersonalInfoHint)));
      return;
    }
    if (!_isDirty) return;

    _studentBloc.add(
      StudentPersonalInfoUpdateRequested(
        studentId: widget.studentDetail.id,
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
    return BlocProvider<StudentBloc>.value(
      value: _studentBloc,
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
        onSavingChanged: widget.onSavingChanged,
        onSaveSuccess: () {
          _markCurrentAsSavedSnapshot();
          _recomputeFormState();
          widget.onSaveSuccess?.call();
        },
      ),
    );
  }
}
