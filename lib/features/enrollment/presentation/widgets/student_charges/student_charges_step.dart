import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_error_l10n_extension.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step_body.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesStep extends StatefulWidget {
  final String studentId;
  final String levelId;
  final EnrollmentStatus enrollmentStatus;
  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final bool isEditable;

  const StudentChargesStep({
    super.key,
    required this.studentId,
    required this.levelId,
    required this.enrollmentStatus,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.isEditable = true,
  });

  @override
  State<StudentChargesStep> createState() => StudentChargesStepState();
}

class StudentChargesStepState extends State<StudentChargesStep> {
  late final StudentChargesBloc _studentChargesBloc;
  final Map<String, TextEditingController> _amountControllers =
      <String, TextEditingController>{};

  List<StudentCharge> _studentCharges = const [];
  Map<String, double> _savedAmounts = <String, double>{};

  bool _isDirty = false;
  bool _isValid = false;
  bool _isSaving = false;
  bool _showValidationHints = false;
  bool _isBatchSaving = false;
  bool _waitingForUpdateResult = false;
  final List<StudentChargeExpectedAmountUpdateRequested> _pendingUpdates =
      <StudentChargeExpectedAmountUpdateRequested>[];

  bool get _canFetch =>
      widget.studentId.trim().isNotEmpty && widget.levelId.trim().isNotEmpty;

  bool get _canEditAmounts =>
      widget.isEditable &&
      widget.enrollmentStatus == EnrollmentStatus.inProgress;

  StepFormState get _stepState =>
      StepFormState(dirty: _isDirty, valid: _isValid, saving: _isSaving);

  void submitForm() => _onSave();

  @override
  void initState() {
    super.initState();
    _studentChargesBloc = getIt<StudentChargesBloc>();

    if (_canFetch) {
      _requestCharges();
    }

    _recomputeFormState(notifyParent: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });
  }

  @override
  void didUpdateWidget(covariant StudentChargesStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    final identifiersChanged =
        oldWidget.studentId != widget.studentId ||
        oldWidget.levelId != widget.levelId;

    if (identifiersChanged) {
      _resetDraftState();
      if (_canFetch) {
        _requestCharges();
      }
      _recomputeFormState(notifyParent: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _emitStepState();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    _studentChargesBloc.close();
    super.dispose();
  }

  void _requestCharges() {
    _studentChargesBloc.add(
      StudentChargesRequested(
        studentId: widget.studentId,
        levelId: widget.levelId,
      ),
    );
  }

  List<StudentChargeExpectedAmountUpdateRequested> _buildPendingUpdates() {
    final updates = <StudentChargeExpectedAmountUpdateRequested>[];

    for (final charge in _studentCharges) {
      final draftAmount = _draftAmountFor(charge);
      final savedAmount =
          _savedAmounts[charge.id] ?? charge.expectedAmountInCents;
      if (draftAmount == savedAmount) {
        continue;
      }

      updates.add(
        StudentChargeExpectedAmountUpdateRequested(
          studentChargeId: charge.id,
          studentId: widget.studentId,
          expectedAmountInCents: draftAmount,
        ),
      );
    }

    return updates;
  }

  void _dispatchNextPendingUpdate() {
    if (!_isBatchSaving || _pendingUpdates.isEmpty) {
      return;
    }

    final event = _pendingUpdates.removeAt(0);
    _waitingForUpdateResult = true;
    _studentChargesBloc.add(event);
  }

  void _finishBatchWithSuccess(AppLocalizations l10n) {
    _isBatchSaving = false;
    _waitingForUpdateResult = false;
    _pendingUpdates.clear();
    _onSavingChanged(false);
    _recomputeFormState();
    AppSnackBar.showSuccess(context, l10n.studentChargesSaveSuccess);
  }

  void _finishBatchWithFailure(
    AppLocalizations l10n,
    StudentChargesErrorType errorType,
  ) {
    _isBatchSaving = false;
    _waitingForUpdateResult = false;
    _pendingUpdates.clear();
    _onSavingChanged(false);
    _recomputeFormState();
    AppSnackBar.showError(context, errorType.localizedMessage(l10n));
  }

  void _resetDraftState() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    _amountControllers.clear();
    _studentCharges = const [];
    _savedAmounts = <String, double>{};
    _isDirty = false;
    _isValid = false;
    _isSaving = false;
    _showValidationHints = false;
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

  void _onSavingChanged(bool saving) {
    if (_isSaving == saving) return;
    setState(() => _isSaving = saving);
    _emitStepState();
  }

  void _syncChargesFromState(List<StudentCharge> charges) {
    final nextIds = charges.map((e) => e.id).toSet();
    final removedIds = _amountControllers.keys
        .where((id) => !nextIds.contains(id))
        .toList(growable: false);

    for (final id in removedIds) {
      _amountControllers.remove(id)?.dispose();
    }

    for (final charge in charges) {
      final controller = _amountControllers.putIfAbsent(
        charge.id,
        () => TextEditingController(),
      );
      controller.text = _formatAmount(charge.expectedAmountInCents);
    }

    _studentCharges = charges;
    _savedAmounts = {
      for (final charge in charges) charge.id: charge.expectedAmountInCents,
    };
  }

  String _formatAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  double? _parseAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  double _draftAmountFor(StudentCharge charge) {
    final controller = _amountControllers[charge.id];
    final parsed = _parseAmount(controller?.text ?? '');
    return parsed ?? _savedAmounts[charge.id] ?? charge.expectedAmountInCents;
  }

  Map<String, String?> _buildAmountErrors(AppLocalizations l10n) {
    if (!(_showValidationHints || (_isDirty && !_isValid))) {
      return <String, String?>{};
    }

    return {
      for (final charge in _studentCharges)
        charge.id:
            _parseAmount(_amountControllers[charge.id]?.text ?? '') == null
            ? l10n.invalidNumberFieldError(l10n.studentChargesAmountColumn)
            : null,
    };
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final currentStatus = _studentChargesBloc.state.status;

    bool nextValid = false;
    bool nextDirty = false;

    if (_canFetch && currentStatus == StudentChargesStatus.success) {
      if (_canEditAmounts) {
        nextValid = _studentCharges.every(
          (charge) =>
              _parseAmount(_amountControllers[charge.id]?.text ?? '') != null,
        );

        nextDirty = _studentCharges.any((charge) {
          final currentValue = _parseAmount(
            _amountControllers[charge.id]?.text ?? '',
          );
          final savedValue =
              _savedAmounts[charge.id] ?? charge.expectedAmountInCents;
          return currentValue == null || currentValue != savedValue;
        });
      } else {
        nextValid = true;
        nextDirty = false;
      }
    }

    if (_isValid != nextValid || _isDirty != nextDirty) {
      setState(() {
        _isValid = nextValid;
        _isDirty = nextDirty;
      });
    }

    if (notifyParent) {
      _emitStepState();
    }
  }

  void _onAmountChanged(String _) {
    _recomputeFormState();
  }

  void _onSave() {
    if (!_canEditAmounts) return;

    if (!_isValid) {
      setState(() => _showValidationHints = true);
      _emitStepState();
      return;
    }

    if (!_isDirty) return;

    final updates = _buildPendingUpdates();
    if (updates.isEmpty) return;

    _pendingUpdates
      ..clear()
      ..addAll(updates);

    _isBatchSaving = true;
    _onSavingChanged(true);
    _dispatchNextPendingUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider<StudentChargesBloc>.value(
      value: _studentChargesBloc,
      child: BlocConsumer<StudentChargesBloc, StudentChargesState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.studentCharges != curr.studentCharges ||
            prev.errorType != curr.errorType,
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;

          if (state.status == StudentChargesStatus.success) {
            _syncChargesFromState(state.studentCharges);

            if (_isBatchSaving && _waitingForUpdateResult) {
              _waitingForUpdateResult = false;

              if (_pendingUpdates.isEmpty) {
                _finishBatchWithSuccess(l10n);
              } else {
                _dispatchNextPendingUpdate();
              }

              if (_showValidationHints) {
                setState(() => _showValidationHints = false);
              }
              return;
            }

            _onSavingChanged(false);
            _recomputeFormState();
          } else if (state.status == StudentChargesStatus.failure) {
            if (_isBatchSaving && _waitingForUpdateResult) {
              _waitingForUpdateResult = false;
              _finishBatchWithFailure(l10n, state.errorType);
              return;
            }

            _onSavingChanged(false);
            _recomputeFormState();
          } else if (state.status == StudentChargesStatus.loading) {
            _recomputeFormState();
          }
        },
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.studentCharges != curr.studentCharges ||
            prev.errorType != curr.errorType,
        builder: (context, state) {
          return StudentChargesStepBody(
            l10n: l10n,
            status: state.status,
            errorType: state.errorType,
            studentCharges: state.studentCharges,
            amountControllers: _amountControllers,
            amountErrors: _buildAmountErrors(l10n),
            isEditable: _canEditAmounts,
            onRetry: _requestCharges,
            onAmountChanged: _onAmountChanged,
            unavailableMessage: _canFetch
                ? null
                : l10n.studentChargesUnavailable,
          );
        },
      ),
    );
  }
}
