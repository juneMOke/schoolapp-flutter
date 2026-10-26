import 'package:equatable/equatable.dart';

/// Ce qui reste dû sur la paie validée d'un mois, dans une devise.
class PayrollDashboardDue extends Equatable {
  /// `YYYY-MM`, le mois d'origine.
  final String month;
  final String currency;
  final int dueInCents;
  final bool prioritized;

  const PayrollDashboardDue({
    required this.month,
    required this.currency,
    required this.dueInCents,
    this.prioritized = false,
  });

  @override
  List<Object?> get props => [month, currency, dueInCents, prioritized];
}

/// Les arriérés d'un agent, un par mois d'origine et par devise, du plus
/// ancien au plus récent.
class PayrollDashboardArrears extends Equatable {
  final String staffMemberId;
  final String fullName;
  final List<PayrollDashboardDue> dues;

  const PayrollDashboardArrears({
    required this.staffMemberId,
    required this.fullName,
    this.dues = const [],
  });

  int dueIn(String currency) => dues
      .where((due) => due.currency == currency)
      .fold(0, (sum, due) => sum + due.dueInCents);

  @override
  List<Object?> get props => [staffMemberId, fullName, dues];
}
