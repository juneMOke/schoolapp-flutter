import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';

enum PayrollLoad { loading, ready, failure }

enum PayrollTab { ledger, payslips, advances, history }

enum PayrollPayFilter { all, toPay, paid }

enum PayrollAdvanceFilter { ongoing, settled, all }

/// L'écran de la paie : ce que la tablette sait, le mois ouvert, son livre
/// composé, et les filtres en mémoire.
class PayrollState extends Equatable {
  final PayrollLoad load;
  final Failure? failure;
  final PayrollSnapshot snapshot;

  /// `YYYY-MM-DD` — borne la navigation et date les écritures.
  final String today;

  /// `YYYY-MM`, partagé par le livre et les bulletins.
  final String month;
  final PayrollTab tab;

  /// Le livre de [month], recomposé quand la tablette ou le mois change.
  final PayrollMonthView? view;
  final StaffContractKind? contractFilter;
  final PayrollPayFilter payFilter;
  final String search;
  final PayrollAdvanceFilter advanceFilter;

  /// L'agent dont le bulletin est ouvert ; `null` = le premier du livre.
  final String? payslipMemberId;
  final PayrollNotice? notice;

  const PayrollState({
    required this.load,
    required this.snapshot,
    required this.today,
    required this.month,
    this.failure,
    this.tab = PayrollTab.ledger,
    this.view,
    this.contractFilter,
    this.payFilter = PayrollPayFilter.all,
    this.search = '',
    this.advanceFilter = PayrollAdvanceFilter.ongoing,
    this.payslipMemberId,
    this.notice,
  });

  factory PayrollState.initial(String today) => PayrollState(
    load: PayrollLoad.loading,
    snapshot: PayrollSnapshot.empty,
    today: today,
    month: today.substring(0, 7),
  );

  String get currentMonth => today.substring(0, 7);

  bool get isCurrentMonth => month == currentMonth;

  /// Pas de paie avant le premier contrat de l'école.
  bool get canStepBack {
    final first = snapshot.firstMonth;
    return first == null || month.compareTo(first) > 0;
  }

  bool get hasFilters =>
      contractFilter != null ||
      payFilter != PayrollPayFilter.all ||
      search.trim().isNotEmpty;

  /// Les lignes du livre après filtres, dans l'ordre de l'état civil.
  List<PayrollLine> get visibleLines {
    final view = this.view;
    if (view == null) return const [];
    final needle = search.trim();
    return [
      for (final member in snapshot.members)
        if (view.line(member.id) case final line?)
          if ((contractFilter == null || line.contractKind == contractFilter) &&
              _matchesPay(view, line) &&
              (needle.isEmpty || StaffMemberSearch.matches(member, needle)))
            line,
    ];
  }

  bool _matchesPay(PayrollMonthView view, PayrollLine line) {
    final paid = view.disbursements.containsKey(line.staffMemberId);
    return switch (payFilter) {
      PayrollPayFilter.all => true,
      PayrollPayFilter.toPay => !paid && line.netInCents > 0,
      PayrollPayFilter.paid => paid,
    };
  }

  PayrollState copyWith({
    PayrollLoad? load,
    Failure? failure,
    bool clearFailure = false,
    PayrollSnapshot? snapshot,
    String? today,
    String? month,
    PayrollTab? tab,
    PayrollMonthView? view,
    StaffContractKind? Function()? contractFilter,
    PayrollPayFilter? payFilter,
    String? search,
    PayrollAdvanceFilter? advanceFilter,
    String? Function()? payslipMemberId,
    PayrollNotice? notice,
  }) => PayrollState(
    load: load ?? this.load,
    failure: clearFailure ? null : failure ?? this.failure,
    snapshot: snapshot ?? this.snapshot,
    today: today ?? this.today,
    month: month ?? this.month,
    tab: tab ?? this.tab,
    view: view ?? this.view,
    contractFilter: contractFilter == null
        ? this.contractFilter
        : contractFilter(),
    payFilter: payFilter ?? this.payFilter,
    search: search ?? this.search,
    advanceFilter: advanceFilter ?? this.advanceFilter,
    payslipMemberId: payslipMemberId == null
        ? this.payslipMemberId
        : payslipMemberId(),
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    load,
    failure,
    snapshot,
    today,
    month,
    tab,
    view,
    contractFilter,
    payFilter,
    search,
    advanceFilter,
    payslipMemberId,
    notice,
  ];
}
