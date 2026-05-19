import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_widgets.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesStep extends StatefulWidget {
  final String studentId;
  final String levelId;
  final EnrollmentStatus enrollmentStatus;
  final bool showInlineSaveButton;
  final int? flowStepIndex;
  final bool isEditable;
  final EnrollmentStepSubmitController? stepController;

  const StudentChargesStep({
    super.key,
    required this.studentId,
    required this.levelId,
    required this.enrollmentStatus,
    this.showInlineSaveButton = true,
    this.flowStepIndex,
    this.isEditable = true,
    this.stepController,
  });

  @override
  State<StudentChargesStep> createState() => StudentChargesStepState();
}

class StudentChargesStepState extends State<StudentChargesStep> {
  late final StudentChargesBloc _studentChargesBloc;
  late final StudentChargesStepController _controller;

  bool get _canFetch =>
      widget.studentId.trim().isNotEmpty && widget.levelId.trim().isNotEmpty;

  bool get _canEditAmounts =>
      widget.isEditable &&
      widget.enrollmentStatus == EnrollmentStatus.inProgress;

  void submitForm() => _onSave();

  @override
  void initState() {
    super.initState();
    _studentChargesBloc = getIt<StudentChargesBloc>();
    _controller = StudentChargesStepController();

    if (_canFetch) {
      _requestCharges();
    }

    _recomputeFormState(notifyParent: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitStepState();
    });

    widget.stepController?.bind(submitForm);
  }

  @override
  void didUpdateWidget(covariant StudentChargesStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stepController != widget.stepController) {
      oldWidget.stepController?.unbind(submitForm);
      widget.stepController?.bind(submitForm);
    }

    final identifiersChanged =
        oldWidget.studentId != widget.studentId ||
        oldWidget.levelId != widget.levelId;

    if (identifiersChanged) {
      _controller.resetDraftState();
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
    widget.stepController?.unbind(submitForm);
    _controller.dispose();
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

  void _emitStepState() {
    final flowStepIndex = widget.flowStepIndex;
    if (flowStepIndex != null && mounted) {
      context.read<EnrollmentStepperFlowBloc>().add(
        EnrollmentStepperStepStateReported(
          step: flowStepIndex,
          stepState: _controller.stepState,
        ),
      );
    }
  }

  void _setSaving(bool saving) {
    if (_controller.isSaving == saving) return;
    setState(() => _controller.isSaving = saving);
    _emitStepState();
  }

  String _formatAmount(double amount) => formatMonetaryAmount(amount);

  double? _parseAmount(String rawValue) => parseMonetaryAmount(rawValue);

  Map<String, String?> _buildAmountErrors(AppLocalizations l10n) {
    return _controller.buildAmountErrors(
      resolveError: (charge) {
        final rawValue = _controller.amountControllers[charge.id]?.text ?? '';
        return _parseAmount(rawValue) == null
            ? l10n.invalidNumberFieldError(l10n.studentChargesAmountColumn)
            : null;
      },
    );
  }

  void _recomputeFormState({bool notifyParent = true}) {
    final changed = _controller.recomputeFormState(
      canFetch: _canFetch,
      canEditAmounts: _canEditAmounts,
      currentStatus: _studentChargesBloc.state.status,
      parseAmount: _parseAmount,
    );

    if (changed) {
      setState(() {});
    }

    if (notifyParent) {
      _emitStepState();
    }
  }

  void _onAmountChanged(String _) {
    _recomputeFormState();
  }

  void _dispatchNextPendingUpdate() {
    final event = _controller.dispatchNextPendingUpdate();
    if (event == null) return;
    _studentChargesBloc.add(event);
  }

  void _finishBatchWithSuccess(AppLocalizations l10n) {
    _controller.finishBatch();
    _setSaving(false);
    _recomputeFormState();
    AppSnackBar.showSuccess(context, l10n.studentChargesSaveSuccess);
  }

  void _finishBatchWithFailure(
    AppLocalizations l10n,
    StudentChargesErrorType errorType,
  ) {
    _controller.finishBatch();
    _setSaving(false);
    _recomputeFormState();
    AppSnackBar.showError(context, errorType.localizedMessage(l10n));
  }

  void _onSave() {
    if (!_canEditAmounts) return;

    if (!_controller.isValid) {
      setState(() => _controller.showValidationHints = true);
      _emitStepState();
      return;
    }

    if (!_controller.isDirty) return;

    final updates = _controller.buildPendingUpdates(
      studentId: widget.studentId,
      parseAmount: _parseAmount,
    );
    if (updates.isEmpty) return;

    _controller.startBatchSaving(updates);
    _setSaving(true);
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
            _controller.syncChargesFromState(
              state.studentCharges,
              formatAmount: _formatAmount,
            );

            if (_controller.isBatchSaving &&
                _controller.waitingForUpdateResult) {
              _controller.waitingForUpdateResult = false;

              if (!_controller.hasPendingUpdates) {
                _finishBatchWithSuccess(l10n);
              } else {
                _dispatchNextPendingUpdate();
              }

              if (_controller.showValidationHints) {
                setState(() => _controller.showValidationHints = false);
              }
              return;
            }

            _setSaving(false);
            _recomputeFormState();
          } else if (state.status == StudentChargesStatus.failure) {
            if (_controller.isBatchSaving &&
                _controller.waitingForUpdateResult) {
              _controller.waitingForUpdateResult = false;
              _finishBatchWithFailure(l10n, state.errorType);
              return;
            }

            _setSaving(false);
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
            amountControllers: _controller.amountControllers,
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
