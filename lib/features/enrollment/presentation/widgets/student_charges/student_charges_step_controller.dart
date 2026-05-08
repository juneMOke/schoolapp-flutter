import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';

class StudentChargesStepController {
  final Map<String, TextEditingController> amountControllers =
      <String, TextEditingController>{};

  List<StudentCharge> _studentCharges = const [];
  Map<String, double> _savedAmounts = <String, double>{};

  bool isDirty = false;
  bool isValid = false;
  bool isSaving = false;
  bool showValidationHints = false;
  bool isBatchSaving = false;
  bool waitingForUpdateResult = false;

  final List<StudentChargeExpectedAmountUpdateRequested> _pendingUpdates =
      <StudentChargeExpectedAmountUpdateRequested>[];

  List<StudentCharge> get studentCharges => _studentCharges;

  StepFormState get stepState =>
      StepFormState(dirty: isDirty, valid: isValid, saving: isSaving);

  bool get hasPendingUpdates => _pendingUpdates.isNotEmpty;

  void dispose() {
    for (final controller in amountControllers.values) {
      controller.dispose();
    }
  }

  void resetDraftState() {
    dispose();
    amountControllers.clear();
    _studentCharges = const [];
    _savedAmounts = <String, double>{};
    isDirty = false;
    isValid = false;
    isSaving = false;
    showValidationHints = false;
    isBatchSaving = false;
    waitingForUpdateResult = false;
    _pendingUpdates.clear();
  }

  void syncChargesFromState(
    List<StudentCharge> charges, {
    required String Function(double amount) formatAmount,
  }) {
    final nextIds = charges.map((e) => e.id).toSet();
    final removedIds = amountControllers.keys
        .where((id) => !nextIds.contains(id))
        .toList(growable: false);

    for (final id in removedIds) {
      amountControllers.remove(id)?.dispose();
    }

    for (final charge in charges) {
      final controller = amountControllers.putIfAbsent(
        charge.id,
        () => TextEditingController(),
      );
      controller.text = formatAmount(charge.expectedAmountInCents);
    }

    _studentCharges = charges;
    _savedAmounts = {
      for (final charge in charges) charge.id: charge.expectedAmountInCents,
    };
  }

  double draftAmountFor(
    StudentCharge charge, {
    required double? Function(String rawValue) parseAmount,
  }) {
    final controller = amountControllers[charge.id];
    final parsed = parseAmount(controller?.text ?? '');
    return parsed ?? _savedAmounts[charge.id] ?? charge.expectedAmountInCents;
  }

  List<StudentChargeExpectedAmountUpdateRequested> buildPendingUpdates({
    required String studentId,
    required double? Function(String rawValue) parseAmount,
  }) {
    final updates = <StudentChargeExpectedAmountUpdateRequested>[];

    for (final charge in _studentCharges) {
      final draftAmount = draftAmountFor(charge, parseAmount: parseAmount);
      final savedAmount =
          _savedAmounts[charge.id] ?? charge.expectedAmountInCents;
      if (draftAmount == savedAmount) {
        continue;
      }

      updates.add(
        StudentChargeExpectedAmountUpdateRequested(
          studentChargeId: charge.id,
          studentId: studentId,
          expectedAmountInCents: draftAmount,
        ),
      );
    }

    return updates;
  }

  bool recomputeFormState({
    required bool canFetch,
    required bool canEditAmounts,
    required StudentChargesStatus currentStatus,
    required double? Function(String rawValue) parseAmount,
  }) {
    bool nextValid = false;
    bool nextDirty = false;

    if (canFetch && currentStatus == StudentChargesStatus.success) {
      if (canEditAmounts) {
        nextValid = _studentCharges.every(
          (charge) =>
              parseAmount(amountControllers[charge.id]?.text ?? '') != null,
        );

        nextDirty = _studentCharges.any((charge) {
          final currentValue = parseAmount(
            amountControllers[charge.id]?.text ?? '',
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

    final changed = isValid != nextValid || isDirty != nextDirty;
    isValid = nextValid;
    isDirty = nextDirty;
    return changed;
  }

  Map<String, String?> buildAmountErrors({
    required String? Function(StudentCharge charge) resolveError,
  }) {
    if (!(showValidationHints || (isDirty && !isValid))) {
      return <String, String?>{};
    }

    return {
      for (final charge in _studentCharges) charge.id: resolveError(charge),
    };
  }

  void startBatchSaving(
    List<StudentChargeExpectedAmountUpdateRequested> updates,
  ) {
    _pendingUpdates
      ..clear()
      ..addAll(updates);
    isBatchSaving = true;
    waitingForUpdateResult = false;
  }

  StudentChargeExpectedAmountUpdateRequested? dispatchNextPendingUpdate() {
    if (!isBatchSaving || _pendingUpdates.isEmpty) {
      return null;
    }

    waitingForUpdateResult = true;
    return _pendingUpdates.removeAt(0);
  }

  void finishBatch() {
    isBatchSaving = false;
    waitingForUpdateResult = false;
    _pendingUpdates.clear();
  }
}
