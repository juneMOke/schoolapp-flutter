import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address/address_form_content.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AddressStep extends StatefulWidget {
  final StudentDetail studentDetail;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final VoidCallback? onRefreshRequested;
  final bool isEditable;

  const AddressStep({
    super.key,
    required this.studentDetail,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.onRefreshRequested,
    this.isEditable = true,
  });

  @override
  State<AddressStep> createState() => AddressStepState();
}

class AddressStepState extends State<AddressStep> {
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _municipalityController;
  late final TextEditingController _addressController;
  late final StudentBloc _studentBloc;

  String _initialCity = '';
  String _initialDistrict = '';
  String _initialMunicipality = '';
  String _initialAddress = '';

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;

  bool get _canSave => _isDirty && _isValid;

  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  void submitForm() {
    _onSave();
  }

  @override
  void initState() {
    super.initState();
    _studentBloc = getIt<StudentBloc>();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _municipalityController = TextEditingController();
    _addressController = TextEditingController();

    _syncFromStudent(widget.studentDetail, resetSnapshot: true);

    _cityController.addListener(_onFieldChanged);
    _districtController.addListener(_onFieldChanged);
    _municipalityController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

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

  void _syncFromStudent(StudentDetail student, {required bool resetSnapshot}) {
    _isHydratingFromDetail = true;
    try {
      _cityController.text = student.city;
      _districtController.text = student.district;
      _municipalityController.text = student.municipality;
      _addressController.text = student.address;
    } finally {
      _isHydratingFromDetail = false;
    }

    if (resetSnapshot) {
      _initialCity = student.city.trim();
      _initialDistrict = student.district.trim();
      _initialMunicipality = student.municipality.trim();
      _initialAddress = student.address.trim();
    }
  }

  @override
  void didUpdateWidget(covariant AddressStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentDetail != widget.studentDetail) {
      _syncFromStudent(widget.studentDetail, resetSnapshot: true);

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
    _cityController.removeListener(_onFieldChanged);
    _districtController.removeListener(_onFieldChanged);
    _municipalityController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _cityController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _addressController.dispose();
    _studentBloc.close();
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
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();
    final municipality = _municipalityController.text.trim();
    final address = _addressController.text.trim();

    final validNow =
        city.isNotEmpty &&
        district.isNotEmpty &&
        municipality.isNotEmpty &&
        address.isNotEmpty;

    final dirtyNow =
        city != _initialCity ||
        district != _initialDistrict ||
        municipality != _initialMunicipality ||
        address != _initialAddress;

    if (_isValid != validNow || _isDirty != dirtyNow) {
      setState(() {
        _isValid = validNow;
        _isDirty = dirtyNow;
      });
      if (notifyParent) {
        _emitStepState();
      }
    }
  }

  void _onSavingChanged(bool saving) {
    if (_isSaving == saving) return;
    _isSaving = saving;
    _emitStepState();
  }

  void _markCurrentAsSavedSnapshot() {
    _initialCity = _cityController.text.trim();
    _initialDistrict = _districtController.text.trim();
    _initialMunicipality = _municipalityController.text.trim();
    _initialAddress = _addressController.text.trim();
  }

  List<String> _buildValidationErrors(AppLocalizations l10n) {
    final errors = <String>[];
    if (_cityController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.city));
    }
    if (_districtController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.district));
    }
    if (_municipalityController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.municipality));
    }
    if (_addressController.text.trim().isEmpty) {
      errors.add(l10n.requiredFieldError(l10n.fullAddress));
    }
    return errors;
  }

  String? _fieldError(
    String value,
    String fieldLabel,
    AppLocalizations l10n,
    bool showValidation,
  ) {
    if (!showValidation || value.trim().isNotEmpty) return null;
    return l10n.requiredFieldError(fieldLabel);
  }

  void _onSave() {
    if (!widget.isEditable) return;
    final l10n = AppLocalizations.of(context)!;

    if (!_isValid) {
      final reasons = _buildValidationErrors(l10n);
      setState(() => _showValidationHints = true);
      AppSnackBar.showValidationErrors(
        context,
        title: l10n.addressValidationReasonsTitle,
        reasons: reasons,
      );
      return;
    }

    if (!_isDirty) return;

    _studentBloc.add(
      StudentAddressUpdateRequested(
        studentId: widget.studentDetail.id,
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        municipality: _municipalityController.text.trim(),
        address: _addressController.text.trim(),
      ),
    );
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
          if (state.operation != StudentUpdateOperation.address) {
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
            widget.onRefreshRequested?.call();

            AppSnackBar.showSuccess(context, l10n.addressSaveSuccess);
          } else if (state.status == StudentUpdateStatus.failure) {
            _onSavingChanged(false);
            AppSnackBar.showError(
              context,
              l10n.addressSaveError(state.errorMessage ?? ''),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state.status == StudentUpdateStatus.loading &&
              state.operation == StudentUpdateOperation.address;

          return Padding(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            child: AddressFormContent(
              cityController: _cityController,
              districtController: _districtController,
              municipalityController: _municipalityController,
              addressController: _addressController,
              cityErrorText: _fieldError(
                _cityController.text,
                l10n.city,
                l10n,
                showValidation,
              ),
              districtErrorText: _fieldError(
                _districtController.text,
                l10n.district,
                l10n,
                showValidation,
              ),
              municipalityErrorText: _fieldError(
                _municipalityController.text,
                l10n.municipality,
                l10n,
                showValidation,
              ),
              addressErrorText: _fieldError(
                _addressController.text,
                l10n.fullAddress,
                l10n,
                showValidation,
              ),
              showInlineSaveButton: widget.showInlineSaveButton,
              isLoading: isLoading,
              canSave: _canSave,
              onSave: _onSave,
              isEditable: widget.isEditable,
            ),
          );
        },
      ),
    );
  }
}
