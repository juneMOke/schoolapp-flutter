import 'package:school_app_flutter/features/payroll/data/local/attendance_summary_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_calendar_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_share_trace_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/salary_advance_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/staff_pay_profile_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les tables de la paie, réunies : le dépôt les lit ensemble et n'a pas à
/// en connaître le découpage.
class PayrollLocal {
  final PayrollSettingsDao settings;
  final StaffPayProfileDao profiles;
  final PayrollDao payrolls;
  final PayrollVariablesDao variables;
  final PayrollGestureDao gestures;
  final AttendanceSummaryDao summaries;
  final SalaryAdvanceDao advances;
  final PayrollDisbursementDao disbursements;
  final PayrollShareTraceDao shares;
  final PayrollCalendarDao calendar;

  const PayrollLocal({
    required this.settings,
    required this.profiles,
    required this.payrolls,
    required this.variables,
    required this.gestures,
    required this.summaries,
    required this.advances,
    required this.disbursements,
    required this.shares,
    required this.calendar,
  });

  /// Toutes sur la même base (les tests, une base en mémoire).
  factory PayrollLocal.on(DatabaseExecutor db) => PayrollLocal(
    settings: PayrollSettingsDao(db),
    profiles: StaffPayProfileDao(db),
    payrolls: PayrollDao(db),
    variables: PayrollVariablesDao(db),
    gestures: PayrollGestureDao(db),
    summaries: AttendanceSummaryDao(db),
    advances: SalaryAdvanceDao(db),
    disbursements: PayrollDisbursementDao(db),
    shares: PayrollShareTraceDao(db),
    calendar: PayrollCalendarDao(db),
  );
}
