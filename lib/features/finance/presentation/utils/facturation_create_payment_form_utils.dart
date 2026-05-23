import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/models/facturation_create_payment_allocation_draft.dart';

Set<String> collectCreatePaymentCurrencies(
  FacturationCreatePaymentIntent intent,
) {
  return intent.unpaidCharges
      .map((charge) => charge.currency.trim())
      .where((currency) => currency.isNotEmpty)
      .toSet();
}

int parseCreatePaymentAmountInCents(String raw) {
  final parsed = parseMonetaryAmount(raw);
  if (parsed == null || parsed <= 0) {
    return 0;
  }
  return (parsed * 100).round();
}

int computeAllocatedAmountInCents(
  List<TextEditingController> amountControllers,
) {
  return amountControllers.fold<int>(
    0,
    (sum, controller) => sum + parseCreatePaymentAmountInCents(controller.text),
  );
}

String resolveCreatePaymentCurrency({
  required String? selectedCurrency,
  required List<StudentCharge?> selectedCharges,
  required List<StudentCharge> unpaidCharges,
}) {
  final selected = selectedCurrency?.trim() ?? '';
  if (selected.isNotEmpty) {
    return selected;
  }

  for (final charge in selectedCharges) {
    final currency = charge?.currency.trim();
    if (currency != null && currency.isNotEmpty) {
      return currency;
    }
  }

  for (final charge in unpaidCharges) {
    final currency = charge.currency.trim();
    if (currency.isNotEmpty) {
      return currency;
    }
  }

  return '';
}

bool hasAtLeastOneSelectedAllocation(List<StudentCharge?> selectedCharges) {
  return selectedCharges.any((charge) => charge != null);
}

bool isCreatePaymentDraftIndexValid({
  required int index,
  required int draftsLength,
}) => index >= 0 && index < draftsLength;

List<CreatePaymentAllocationInput> buildCreatePaymentAllocations(
  List<FacturationCreatePaymentAllocationDraft> drafts,
) {
  return drafts
      .where((draft) => draft.selectedCharge != null)
      .map(
        (draft) => CreatePaymentAllocationInput(
          studentChargeId: draft.selectedCharge!.id,
          feeCode: draft.selectedCharge!.feeCode,
          studentChargeLabel: draft.selectedCharge!.label,
          amountInCents: parseCreatePaymentAmountInCents(
            draft.amountController.text,
          ),
          currency: draft.selectedCharge!.currency,
        ),
      )
      .toList(growable: false);
}

bool canSubmitCreatePayment({
  required PaymentsState state,
  required bool isSubmitted,
  required List<StudentCharge?> selectedCharges,
  required int allocatedAmountInCents,
  required String currency,
}) {
  if (isSubmitted) {
    return false;
  }
  if (state.createStatus == PaymentsStatus.loading) {
    return false;
  }
  if (!hasAtLeastOneSelectedAllocation(selectedCharges)) {
    return false;
  }
  if (allocatedAmountInCents <= 0) {
    return false;
  }

  return currency.isNotEmpty;
}