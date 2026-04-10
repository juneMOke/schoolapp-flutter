import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_info_widgets.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/parent_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianInfoStep extends StatefulWidget {
  final List<ParentSummary> parentDetails;
  final String enrollmentId;
  final bool showInlineSaveButton;
  final int? flowStepIndex;

  const GuardianInfoStep({
    super.key,
    required this.parentDetails,
    required this.enrollmentId,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
  });

  @override
  State<GuardianInfoStep> createState() => GuardianInfoStepState();
}

class GuardianInfoStepState extends State<GuardianInfoStep> {
  late Map<String, ParentItemValue> _currentValuesByParentId;
  late Map<String, ParentItemValue> _initialValuesByParentId;
  late Map<String, ParentItemFormState> _itemStatesByParentId;

  final List<String> _pendingParentIds = <String>[];
  bool _isBatchSaving = false;

  bool _isDirty = false;
  bool _isValid = false;
  bool _showValidationHints = false;
  bool _isSaving = false;
  bool _isHydratingFromDetail = false;

  bool get _canSave => _stepState.canSave;
  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  late final ParentBloc _parentBloc;

  void submitForm() => _onSave();

  @override
  void initState() {
    super.initState();
    _parentBloc = getIt<ParentBloc>();
    _syncFromParentDetails(widget.parentDetails, resetSnapshot: true);

    _recomputeFormState(notifyParent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

  void _syncFromParentDetails(
    List<ParentSummary> parents, {
    required bool resetSnapshot,
  }) {
    _isHydratingFromDetail = true;
    try {
      _currentValuesByParentId = <String, ParentItemValue>{
        for (final parent in parents) parent.id: ParentItemValue.fromParent(parent),
      };

      _itemStatesByParentId = <String, ParentItemFormState>{
        for (final parent in parents)
          parent.id: ParentItemFormState(
            valid: ParentItemValue.fromParent(parent).isValid,
            dirty: false,
            changedFields: const <String, bool>{},
          ),
      };

      if (resetSnapshot) {
        _initialValuesByParentId = <String, ParentItemValue>{
          for (final parent in parents)
            parent.id: ParentItemValue.fromParent(parent),
        };
      }
    } finally {
      _isHydratingFromDetail = false;
    }
  }

  @override
  void didUpdateWidget(covariant GuardianInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentDetails != widget.parentDetails) {
      _syncFromParentDetails(widget.parentDetails, resetSnapshot: true);
      _pendingParentIds.clear();
      _isBatchSaving = false;
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
    _parentBloc.close();
    super.dispose();
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

  void _recomputeFormState({bool notifyParent = true}) {
    if (_isHydratingFromDetail) return;

    final parentIds = widget.parentDetails.map((p) => p.id).toList(growable: false);

    final validNow =
        parentIds.isNotEmpty &&
        parentIds.every((id) => _itemStatesByParentId[id]?.valid == true);

    final dirtyNow =
        parentIds.any((id) => _itemStatesByParentId[id]?.dirty == true);

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

  void _onParentItemStateChanged(String parentId, ParentItemFormState state) {
    _itemStatesByParentId[parentId] = state;
    _recomputeFormState();
  }

  void _onParentItemValueChanged(String parentId, ParentItemValue value) {
    _currentValuesByParentId[parentId] = value;
    _recomputeFormState();
  }

  List<String> _buildValidationErrors(AppLocalizations l10n) {
    final errors = <String>[];

    if (widget.parentDetails.isEmpty) {
      errors.add(l10n.requiredFieldError('Gardien'));
      return errors;
    }

    for (var i = 0; i < widget.parentDetails.length; i++) {
      final parent = widget.parentDetails[i];
      final value = _currentValuesByParentId[parent.id];
      if (value == null) continue;

      if (value.firstName.trim().isEmpty) {
        errors.add('Gardien ${i + 1}: ${l10n.requiredFieldError(l10n.firstName)}');
      }
      if (value.lastName.trim().isEmpty) {
        errors.add('Gardien ${i + 1}: ${l10n.requiredFieldError(l10n.lastName)}');
      }
      if (value.phoneNumber.trim().isEmpty) {
        errors.add(
          'Gardien ${i + 1}: ${l10n.requiredFieldError(l10n.phoneNumberLabel)}',
        );
      }
      if (value.email.trim().isEmpty) {
        errors.add('Gardien ${i + 1}: ${l10n.requiredFieldError(l10n.emailLabel)}');
      }
    }

    return errors;
  }

  void _queueAndStartSave() {
    _pendingParentIds
      ..clear()
      ..addAll(
        widget.parentDetails
            .where((parent) => _itemStatesByParentId[parent.id]?.dirty == true)
            .map((parent) => parent.id),
      );

    if (_pendingParentIds.isEmpty) return;

    _isBatchSaving = true;
    _dispatchNextParentUpdate();
  }

  void _dispatchNextParentUpdate() {
    if (_pendingParentIds.isEmpty) return;

    final parentId = _pendingParentIds.first;
    final current = _currentValuesByParentId[parentId];
    final initial = _initialValuesByParentId[parentId];

    if (current == null || initial == null) {
      _pendingParentIds.remove(parentId);
      _dispatchNextParentUpdate();
      return;
    }

    final changed = current.changedComparedTo(initial);
    final hasUpdatableChanges = (changed['firstName'] ?? false) ||
        (changed['lastName'] ?? false) ||
        (changed['surname'] ?? false) ||
        (changed['phoneNumber'] ?? false) ||
        (changed['email'] ?? false) ||
        (changed['relationshipType'] ?? false);

    if (!hasUpdatableChanges) {
      _pendingParentIds.remove(parentId);
      _markParentAsSaved(parentId);
      _dispatchNextParentUpdate();
      return;
    }

    _parentBloc.add(
      ParentUpdateRequested(
        parentId: parentId,
        firstName: current.firstName.trim(),
        lastName: current.lastName.trim(),
        surname: current.surname.trim().isEmpty ? null : current.surname.trim(),
        email: current.email.trim(),
        phoneNumber: current.phoneNumber.trim(),
        relationshipType: current.relationshipType.name.toUpperCase(),
      ),
    );
  }

  void _markParentAsSaved(String parentId) {
    final current = _currentValuesByParentId[parentId];
    if (current == null) return;

    _initialValuesByParentId[parentId] = current;
    _itemStatesByParentId[parentId] = ParentItemFormState(
      valid: current.isValid,
      dirty: false,
      changedFields: const <String, bool>{},
    );
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

    if (!_isDirty || _isBatchSaving) return;

    _queueAndStartSave();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parentDetails.isEmpty) {
      return const GuardianEmptyState();
    }

    return BlocProvider<ParentBloc>.value(
      value: _parentBloc,
      child: BlocConsumer<ParentBloc, ParentState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          final savingNow =
              _isBatchSaving || state.status == ParentUpdateStatus.loading;
          _onSavingChanged(savingNow);

          if (state.status == ParentUpdateStatus.success) {
            if (_pendingParentIds.isNotEmpty) {
              final savedParentId = _pendingParentIds.removeAt(0);
              _markParentAsSaved(savedParentId);
            }

            if (_pendingParentIds.isNotEmpty) {
              _dispatchNextParentUpdate();
              return;
            }

            _isBatchSaving = false;
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

            final l10n = AppLocalizations.of(context)!;
            AppSnackBar.showSuccess(context, l10n.academicInfoSaveSuccess);
          } else if (state.status == ParentUpdateStatus.failure) {
            _pendingParentIds.clear();
            _isBatchSaving = false;
            _onSavingChanged(false);

            final l10n = AppLocalizations.of(context)!;
            AppSnackBar.showError(
              context,
              l10n.academicInfoSaveError(state.errorMessage ?? ''),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              _isBatchSaving || state.status == ParentUpdateStatus.loading;

          return GuardianInfoStepBody(
            parentDetails: widget.parentDetails,
            onItemStateChanged: _onParentItemStateChanged,
            onItemValueChanged: _onParentItemValueChanged,
            isLoading: isLoading,
            canSave: _canSave,
            showInlineSaveButton: widget.showInlineSaveButton,
            onSave: _onSave,
          );
        },
      ),
    );
  }
}
