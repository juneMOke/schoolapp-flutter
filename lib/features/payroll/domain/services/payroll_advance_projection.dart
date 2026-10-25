import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ids.dart';

/// L'avance née d'une dépense payée, **avant** que le serveur ne la rende
/// (B5, T10) : la tablette qui décaisse hors ligne la projette sous
/// l'identifiant que le serveur lui donnera — le livre la retient dès le mois
/// choisi, et la vraie avance, une fois descendue, prend sa place sans
/// doublon.
///
/// L'identifiant suit le rang du paiement, comme au serveur : une avance
/// vivante déjà née de la demande la représente ; sinon n = les avances déjà
/// nées de la demande (annulées comprises, une réouverture annule) + 1.
///
/// Un paiement refusé ramène la dépense à « accordée » : la projection
/// disparaît d'elle-même, sans rien à effacer.
abstract final class PayrollAdvanceProjection {
  static List<SalaryAdvance> of(
    List<PayrollAdvanceRequest> requests,
    List<SalaryAdvance> advances,
  ) {
    final born = <String, List<SalaryAdvance>>{};
    for (final advance in advances) {
      if (advance.expenseId case final expenseId?) {
        (born[expenseId] ??= []).add(advance);
      }
    }
    return [
      for (final request in requests)
        ?_projected(request, born[request.expenseId] ?? const []),
    ];
  }

  static SalaryAdvance? _projected(
    PayrollAdvanceRequest request,
    List<SalaryAdvance> born,
  ) {
    final firstMonth = request.block.firstMonth;
    if (request.status != ExpenseStatus.paid || firstMonth == null) {
      return null;
    }
    if (born.any((advance) => !advance.isCancelled)) return null;
    final id = PayrollIds.salaryAdvanceIdOf(
      request.expenseId,
      payment: born.length + 1,
    );
    return SalaryAdvance(
      id: id,
      staffMemberId: request.staffMemberId,
      amount: request.amount,
      installments: request.block.installments,
      firstMonth: firstMonth,
      reason:
          SalaryAdvanceReason.fromWire(request.block.reason) ??
          SalaryAdvanceReason.other,
      reasonDetail: request.block.reasonDetail,
      mode: switch (request.fundingSource) {
        ExpenseFundingSource.cash => PayoutMode.cash,
        ExpenseFundingSource.mobileMoney => PayoutMode.mobileMoney,
        ExpenseFundingSource.bank => PayoutMode.bank,
      },
      grantedOn: request.paidOn ?? '$firstMonth-01',
      expenseId: request.expenseId,
      syncState: RecordSyncState.pending,
    );
  }
}
