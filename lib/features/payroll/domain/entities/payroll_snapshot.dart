import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// Tout ce que la tablette sait de la paie, lu en une fois — lecture 100 %
/// locale. Les lignes d'un mois non validé n'y sont pas : elles se calculent.
class PayrollSnapshot {
  final List<StaffMember> members;
  final Map<String, List<StaffContract>> contractsByMember;
  final PayrollSettings settings;
  final Map<String, StaffPayProfile> profiles;

  /// Par mois `YYYY-MM`.
  final Map<String, PayrollHeader> headers;
  final Map<String, Map<String, PayrollVariables>> variables;
  final Map<String, List<PayrollLine>> frozenLines;
  final Map<String, AttendanceSummary> summaries;

  /// Dans l'ordre de pose.
  final List<PayrollGesture> gestures;
  final List<SalaryAdvance> advances;
  final List<PayrollDisbursement> disbursements;
  final List<PayrollSchoolYear> schoolYears;

  /// `mois|agent` → canal → instant.
  final Map<String, Map<PayrollShareChannel, String>> shareTraces;

  /// Le fichier du personnel est-il déjà descendu une fois ?
  final bool hasEverSynced;

  /// L'établissement, pour l'en-tête des bulletins ; `null` tant que le
  /// référentiel n'est pas descendu.
  final School? school;

  const PayrollSnapshot({
    required this.members,
    required this.contractsByMember,
    required this.settings,
    required this.profiles,
    required this.headers,
    required this.variables,
    required this.frozenLines,
    required this.summaries,
    required this.gestures,
    required this.advances,
    required this.disbursements,
    required this.schoolYears,
    required this.shareTraces,
    required this.hasEverSynced,
    this.school,
  });

  static const PayrollSnapshot empty = PayrollSnapshot(
    members: [],
    contractsByMember: {},
    settings: PayrollSettings.defaults,
    profiles: {},
    headers: {},
    variables: {},
    frozenLines: {},
    summaries: {},
    gestures: [],
    advances: [],
    disbursements: [],
    schoolYears: [],
    shareTraces: {},
    hasEverSynced: false,
  );

  static String traceKey(String month, String staffMemberId) =>
      '$month|$staffMemberId';

  /// La fiche d'un agent — sans égard à la casse : les lignes réduites d'un
  /// refus portent l'identifiant en minuscules.
  StaffMember? member(String id) {
    final wanted = id.toLowerCase();
    for (final member in members) {
      if (member.id.toLowerCase() == wanted) return member;
    }
    return null;
  }

  /// Le premier mois payable : celui du plus ancien contrat de l'école.
  String? get firstMonth {
    String? first;
    for (final contracts in contractsByMember.values) {
      for (final contract in contracts) {
        final month = contract.effectiveFrom.substring(0, 7);
        if (first == null || month.compareTo(first) < 0) first = month;
      }
    }
    return first;
  }
}
