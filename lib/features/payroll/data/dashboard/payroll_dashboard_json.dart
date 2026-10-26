import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';

typedef _Json = Map<String, dynamic>;

/// Miroir de `PayrollDashboardResponse` (`GET /hr/payrolls/{month}/dashboard`).
///
/// Strict sur ce qui fait les chiffres : un montant manquant fait échouer la
/// lecture plutôt que d'afficher un zéro qui n'a pas été compté. Seuls les
/// blocs que le serveur omet pour un mois d'avant la v2 (`progress`, `rows`,
/// `totals`) sont facultatifs.
abstract final class PayrollDashboardJson {
  static PayrollDashboard fromJson(Map<String, dynamic> json) =>
      PayrollDashboard(
        month: json['month'] as String,
        status: PayrollMonthStatus.fromWire(json['status'] as String?),
        validatedAt: json['validatedAt'] as String?,
        provisional: json['provisional'] as bool,
        situationAt: json['situationAt'] as String,
        tracked: json['tracked'] as bool,
        currencies: [
          for (final raw in _list(json['currencies'])) _currency(raw as _Json),
        ],
        months: [for (final raw in _list(json['months'])) _month(raw as _Json)],
        advances: [
          for (final raw in _list(json['advances'])) _advance(raw as _Json),
        ],
        arrears: [
          for (final raw in _list(json['arrears'])) _arrears(raw as _Json),
        ],
      );

  static List<dynamic> _list(Object? raw) => raw as List<dynamic>? ?? const [];

  static int _cents(_Json json, String key) => (json[key] as num).toInt();

  static PayrollDashboardCurrency _currency(_Json json) {
    final progress = json['progress'] as _Json?;
    final totals = json['totals'] as _Json?;
    return PayrollDashboardCurrency(
      currency: json['currency'] as String,
      forecast: _forecast(json['forecast'] as _Json),
      priorityArrearsInCents: _cents(json, 'priorityArrearsInCents'),
      progress: progress == null ? null : _progress(progress),
      rows: [for (final raw in _list(json['rows'])) _row(raw as _Json)],
      totals: totals == null ? null : _totals(totals),
    );
  }

  static PayrollDashboardForecast _forecast(_Json json) =>
      PayrollDashboardForecast(
        grossInCents: _cents(json, 'grossInCents'),
        absenceInCents: _cents(json, 'absenceInCents'),
        advancesInCents: _cents(json, 'advancesInCents'),
        legalInCents: _cents(json, 'legalInCents'),
        childcareInCents: _cents(json, 'childcareInCents'),
        netInCents: _cents(json, 'netInCents'),
        employerChargesInCents: _cents(json, 'employerChargesInCents'),
      );

  static PayrollNetProgress _progress(_Json json, {bool counters = true}) =>
      PayrollNetProgress(
        paidInCents: _cents(json, 'paidInCents'),
        deferredInCents: _cents(json, 'deferredInCents'),
        unpaidInCents: _cents(json, 'unpaidInCents'),
        notYetInCents: _cents(json, 'notYetInCents'),
        settledCount: counters ? _cents(json, 'settledCount') : 0,
        partialCount: counters ? _cents(json, 'partialCount') : 0,
        unpaidCount: counters ? _cents(json, 'unpaidCount') : 0,
      );

  static PayrollDashboardRow _row(_Json json) => PayrollDashboardRow(
    staffMemberId: json['staffMemberId'] as String,
    fullName: json['fullName'] as String,
    jobTitle: json['jobTitle'] as String?,
    plannedInCents: _cents(json, 'plannedInCents'),
    deductionsInCents: _cents(json, 'deductionsInCents'),
    netInCents: _cents(json, 'netInCents'),
    arrearsInCents: _cents(json, 'arrearsInCents'),
    receivedInCents: _cents(json, 'receivedInCents'),
    remainingInCents: _cents(json, 'remainingInCents'),
    status: PayrollDashboardStatus.fromWire(json['status'] as String?),
  );

  static PayrollDashboardTotals _totals(_Json json) => PayrollDashboardTotals(
    plannedInCents: _cents(json, 'plannedInCents'),
    deductionsInCents: _cents(json, 'deductionsInCents'),
    netInCents: _cents(json, 'netInCents'),
    arrearsInCents: _cents(json, 'arrearsInCents'),
    receivedInCents: _cents(json, 'receivedInCents'),
    remainingInCents: _cents(json, 'remainingInCents'),
  );

  static PayrollDashboardMonth _month(_Json json) => PayrollDashboardMonth(
    month: json['month'] as String,
    status: PayrollMonthStatus.fromWire(json['status'] as String?),
    tracked: json['tracked'] as bool? ?? true,
    byCurrency: {
      for (final raw in _list(json['currencies']))
        (raw as _Json)['currency'] as String: _progress(raw, counters: false),
    },
  );

  static PayrollDashboardAdvance _advance(_Json json) =>
      PayrollDashboardAdvance(
        advanceId: json['advanceId'] as String,
        staffMemberId: json['staffMemberId'] as String,
        fullName: json['fullName'] as String,
        isLoan: json['nature'] == 'LOAN',
        installments: (json['installments'] as num?)?.toInt() ?? 1,
        reason: SalaryAdvanceReason.fromWire(json['reason'] as String?),
        reasonDetail: json['reasonDetail'] as String?,
        grantedOn: json['grantedOn'] as String,
        amountInCents: _cents(json, 'amountInCents'),
        currency: json['currency'] as String,
        remainingInCents: _cents(json, 'remainingInCents'),
        takenThisMonthInCents: _cents(json, 'takenThisMonthInCents'),
        phase: PayrollAdvancePhase.fromWire(json['phase'] as String?),
      );

  static PayrollDashboardArrears _arrears(_Json json) =>
      PayrollDashboardArrears(
        staffMemberId: json['staffMemberId'] as String,
        fullName: json['fullName'] as String,
        dues: [
          for (final raw in _list(json['dues']))
            PayrollDashboardDue(
              month: (raw as _Json)['month'] as String,
              currency: raw['currency'] as String,
              dueInCents: _cents(raw, 'dueInCents'),
              prioritized: raw['prioritized'] as bool? ?? false,
            ),
        ],
      );
}
