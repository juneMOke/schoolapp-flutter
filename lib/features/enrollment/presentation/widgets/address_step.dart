import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address/address_form_content.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address/address_geo_catalog.dart';
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
  late final TextEditingController _additionalAddressController;
  late final StudentBloc _studentBloc;

  String _initialCity = '';
  String _initialDistrict = '';
  String _initialMunicipality = '';
  String _initialAddress = '';
  String _initialAdditionalAddress = '';

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;
  bool _isCatalogLoading = true;
  AddressGeoCatalog? _geoCatalog;

  bool get _canSave => _isDirty && _isValid;

  String? _asNullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? get _selectedCity => _asNullable(_cityController.text);

  String? get _selectedDistrict => _asNullable(_districtController.text);

  String? get _selectedMunicipality =>
      _asNullable(_municipalityController.text);

  String? get _selectedNeighborhood => _asNullable(_addressController.text);

  String get _selectedAdditionalAddress =>
      _additionalAddressController.text.trim();

  ({String neighborhood, String additionalAddress}) _splitAddressValue(
    String rawAddress,
  ) {
    final trimmed = rawAddress.trim();
    if (trimmed.isEmpty) {
      return (neighborhood: '', additionalAddress: '');
    }

    final separatorIndex = trimmed.indexOf(',');
    if (separatorIndex < 0) {
      return (neighborhood: trimmed, additionalAddress: '');
    }

    return (
      neighborhood: trimmed.substring(0, separatorIndex).trim(),
      additionalAddress: trimmed.substring(separatorIndex + 1).trim(),
    );
  }

  ({String neighborhood, String additionalAddress})
  _buildInitialAddressParts(StudentDetail student) {
    final neighborhood = student.neighborhood.trim();
    if (neighborhood.isEmpty) {
      return _splitAddressValue(student.address);
    }

    final rawAddress = student.address.trim();
    if (rawAddress.isEmpty) {
      return (neighborhood: neighborhood, additionalAddress: '');
    }

    final prefixed = '$neighborhood,';
    if (rawAddress.startsWith(prefixed)) {
      return (
        neighborhood: neighborhood,
        additionalAddress: rawAddress.substring(prefixed.length).trim(),
      );
    }

    return (neighborhood: neighborhood, additionalAddress: rawAddress);
  }

  String _buildAddressPayload() {
    return _selectedAdditionalAddress;
  }

  String? get _resolvedCityKey {
    final catalog = _geoCatalog;
    if (catalog == null) {
      return _selectedCity;
    }
    return catalog.resolveCity(_selectedCity);
  }

  String? get _resolvedDistrictKey {
    final catalog = _geoCatalog;
    final city = _resolvedCityKey;
    if (catalog == null || city == null) {
      return _selectedDistrict;
    }
    return catalog.resolveDistrict(city, _selectedDistrict);
  }

  String? get _resolvedMunicipalityKey {
    final catalog = _geoCatalog;
    final city = _resolvedCityKey;
    final district = _resolvedDistrictKey;
    if (catalog == null || city == null || district == null) {
      return _selectedMunicipality;
    }
    return catalog.resolveMunicipality(city, district, _selectedMunicipality);
  }

  String? get _selectedNeighborhoodDisplay {
    final value = _selectedNeighborhood;
    final catalog = _geoCatalog;
    final city = _resolvedCityKey;
    final district = _resolvedDistrictKey;
    final municipality = _resolvedMunicipalityKey;

    if (value == null ||
        catalog == null ||
        city == null ||
        district == null ||
        municipality == null) {
      return value;
    }

    return catalog.neighborhoodDisplayFromName(
      city,
      district,
      municipality,
      value,
    );
  }

  List<String> _singleOrEmpty(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }

    return List<String>.unmodifiable(<String>[trimmed]);
  }

  List<String> get _cityOptions {
    final catalog = _geoCatalog;
    if (catalog == null) {
      return _singleOrEmpty(_cityController.text);
    }

    return catalog.cityOptions(include: _cityController.text.trim());
  }

  List<String> get _districtOptions {
    final catalog = _geoCatalog;
    final city = _resolvedCityKey;
    if (catalog == null || city == null) {
      return _singleOrEmpty(_districtController.text);
    }

    return catalog.districtsForCity(
      city,
      include: _districtController.text.trim(),
    );
  }

  List<String> get _municipalityOptions {
    final catalog = _geoCatalog;
    final city = _resolvedCityKey;
    final district = _resolvedDistrictKey;
    if (catalog == null || city == null || district == null) {
      return _singleOrEmpty(_municipalityController.text);
    }

    return catalog.municipalitiesForDistrict(
      city,
      district,
      include: _municipalityController.text.trim(),
    );
  }

  List<String> get _neighborhoodOptions {
    final catalog = _geoCatalog;
    final city = _resolvedCityKey;
    final district = _resolvedDistrictKey;
    final municipality = _resolvedMunicipalityKey;
    if (catalog == null ||
        city == null ||
        district == null ||
        municipality == null) {
      return _singleOrEmpty(_addressController.text);
    }

    return catalog.neighborhoodsForMunicipality(
      city,
      district,
      municipality,
      include: _selectedNeighborhoodDisplay,
    );
  }

  Future<void> _loadGeoCatalog() async {
    try {
      final catalog = await AddressGeoCatalog.load();
      if (!mounted) return;
      setState(() {
        _geoCatalog = catalog;
        _isCatalogLoading = false;
      });

      _syncSelectionWithCatalog(catalog);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCatalogLoading = false);
    }
  }

  void _syncSelectionWithCatalog(AddressGeoCatalog catalog) {
    final city =
        catalog.resolveCity(_selectedCity) ??
        catalog.resolveCity(AddressGeoCatalog.defaultCity) ??
        catalog.firstCity();

    final district = city == null
        ? null
        : catalog.resolveDistrict(city, _selectedDistrict) ??
              catalog.firstDistrictForCity(city);

    final municipality = city == null || district == null
        ? null
        : catalog.resolveMunicipality(city, district, _selectedMunicipality) ??
              catalog.firstMunicipalityForDistrict(city, district);

    final neighborhood =
        city == null || district == null || municipality == null
        ? null
        : catalog.resolveNeighborhoodName(
                city,
                district,
                municipality,
                _selectedNeighborhood,
              ) ??
              (() {
                final firstDisplay = catalog
                    .firstNeighborhoodDisplayForMunicipality(
                      city,
                      district,
                      municipality,
                    );
                if (firstDisplay == null) {
                  return null;
                }
                return catalog.neighborhoodNameFromDisplay(
                  city,
                  district,
                  municipality,
                  firstDisplay,
                );
              })();

    _setAddressFields(
      city: city,
      district: district ?? '',
      municipality: municipality ?? '',
      neighborhood: neighborhood ?? '',
      additionalAddress: _selectedAdditionalAddress,
    );
    _recomputeFormState();
  }

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
    _additionalAddressController = TextEditingController();

    _syncFromStudent(widget.studentDetail, resetSnapshot: true);

    _cityController.addListener(_onFieldChanged);
    _districtController.addListener(_onFieldChanged);
    _municipalityController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _additionalAddressController.addListener(_onFieldChanged);
    _loadGeoCatalog();

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
    final addressParts = _buildInitialAddressParts(student);

    _isHydratingFromDetail = true;
    try {
      _cityController.text = student.city;
      _districtController.text = student.district;
      _municipalityController.text = student.municipality;
      _addressController.text = addressParts.neighborhood;
      _additionalAddressController.text = addressParts.additionalAddress;
    } finally {
      _isHydratingFromDetail = false;
    }

    if (resetSnapshot) {
      _initialCity = student.city.trim();
      _initialDistrict = student.district.trim();
      _initialMunicipality = student.municipality.trim();
      _initialAddress = addressParts.neighborhood;
      _initialAdditionalAddress = addressParts.additionalAddress;
    }
  }

  void _setAddressFields({
    String? city,
    String? district,
    String? municipality,
    String? neighborhood,
    String? additionalAddress,
  }) {
    _isHydratingFromDetail = true;
    try {
      if (city != null) {
        _cityController.text = city;
      }
      if (district != null) {
        _districtController.text = district;
      }
      if (municipality != null) {
        _municipalityController.text = municipality;
      }
      if (neighborhood != null) {
        _addressController.text = neighborhood;
      }
      if (additionalAddress != null) {
        _additionalAddressController.text = additionalAddress;
      }
    } finally {
      _isHydratingFromDetail = false;
    }
  }

  // Force un rebuild immédiat pour recalculer les listes dépendantes.
  void _refreshDependentDropdowns() {
    setState(() {});
  }

  void _onCityChanged(String? city) {
    final value = city?.trim() ?? '';
    _setAddressFields(
      city: value,
      district: '',
      municipality: '',
      neighborhood: '',
    );
    _refreshDependentDropdowns();
    _recomputeFormState();
  }

  void _onDistrictChanged(String? district) {
    final value = district?.trim() ?? '';
    _setAddressFields(district: value, municipality: '', neighborhood: '');
    _refreshDependentDropdowns();
    _recomputeFormState();
  }

  void _onMunicipalityChanged(String? municipality) {
    final value = municipality?.trim() ?? '';
    _setAddressFields(municipality: value, neighborhood: '');
    _refreshDependentDropdowns();
    _recomputeFormState();
  }

  void _onNeighborhoodChanged(String? neighborhood) {
    final selectedDisplay = neighborhood?.trim() ?? '';
    final catalog = _geoCatalog;
    final city = _resolvedCityKey;
    final district = _resolvedDistrictKey;
    final municipality = _resolvedMunicipalityKey;

    final canonicalValue =
        catalog == null ||
            city == null ||
            district == null ||
            municipality == null
        ? selectedDisplay
        : catalog.neighborhoodNameFromDisplay(
            city,
            district,
            municipality,
            selectedDisplay,
          );

    _setAddressFields(neighborhood: canonicalValue);
    _refreshDependentDropdowns();
    _recomputeFormState();
  }

  @override
  void didUpdateWidget(covariant AddressStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentDetail != widget.studentDetail) {
      _syncFromStudent(widget.studentDetail, resetSnapshot: true);
      final catalog = _geoCatalog;
      if (catalog != null) {
        _syncSelectionWithCatalog(catalog);
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
    _cityController.removeListener(_onFieldChanged);
    _districtController.removeListener(_onFieldChanged);
    _municipalityController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _additionalAddressController.removeListener(_onFieldChanged);
    _cityController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _addressController.dispose();
    _additionalAddressController.dispose();
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
    final additionalAddress = _selectedAdditionalAddress;

    final validNow =
        city.isNotEmpty &&
        district.isNotEmpty &&
        municipality.isNotEmpty &&
        address.isNotEmpty;

    final dirtyNow =
        city != _initialCity ||
        district != _initialDistrict ||
        municipality != _initialMunicipality ||
        address != _initialAddress ||
        additionalAddress != _initialAdditionalAddress;

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
    _initialAdditionalAddress = _selectedAdditionalAddress;
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
      errors.add(l10n.requiredFieldError(l10n.neighborhood));
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
        neighborhood: _addressController.text.trim(),
        address: _buildAddressPayload(),
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
              cityValue: _selectedCity,
              districtValue: _selectedDistrict,
              municipalityValue: _selectedMunicipality,
              neighborhoodValue: _selectedNeighborhoodDisplay,
              cityOptions: _cityOptions,
              districtOptions: _districtOptions,
              municipalityOptions: _municipalityOptions,
              neighborhoodOptions: _neighborhoodOptions,
              onCityChanged: _onCityChanged,
              onDistrictChanged: _onDistrictChanged,
              onMunicipalityChanged: _onMunicipalityChanged,
              onNeighborhoodChanged: _onNeighborhoodChanged,
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
                l10n.neighborhood,
                l10n,
                showValidation,
              ),
              additionalAddressController: _additionalAddressController,
              showInlineSaveButton: widget.showInlineSaveButton,
              isLoading: isLoading,
              isCatalogLoading: _isCatalogLoading,
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
