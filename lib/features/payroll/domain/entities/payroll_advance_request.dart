import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';

/// Une avance ou un prêt **demandé** : une dépense `STAFF_ADVANCE` du
/// registre (B5). La dépense mène le circuit — déposée, accordée, payée — et
/// la Paie n'y lit que ce qu'il faut pour suivre la demande et, une fois
/// payée, projeter l'avance sous l'identifiant que le serveur lui donnera.
class PayrollAdvanceRequest extends Equatable {
  final String expenseId;
  final String? number;
  final ExpenseStaffAdvance block;
  final Money amount;
  final ExpenseStatus status;
  final ExpenseFundingSource fundingSource;

  /// `YYYY-MM-DD`.
  final String? paidOn;
  final String? decidedAt;
  final String? decidedByName;
  final String? decisionReason;

  const PayrollAdvanceRequest({
    required this.expenseId,
    required this.block,
    required this.amount,
    required this.status,
    required this.fundingSource,
    this.number,
    this.paidOn,
    this.decidedAt,
    this.decidedByName,
    this.decisionReason,
  });

  String get staffMemberId => block.staffMemberId;

  /// Encore dans le circuit : à valider, ou accordée et à décaisser.
  bool get isInCircuit =>
      status == ExpenseStatus.pending || status == ExpenseStatus.approved;

  @override
  List<Object?> get props => [
    expenseId,
    number,
    block,
    amount,
    status,
    fundingSource,
    paidOn,
    decidedAt,
    decidedByName,
    decisionReason,
  ];
}
