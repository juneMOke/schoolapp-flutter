import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';

/// Tout ce que la tablette sait du Pointage sur une plage de jours, lu en une
/// fois : les agents (le fichier du personnel), leurs pointages, les jours
/// validés et mois clos, les réglages.
class StaffAttendanceSnapshot extends Equatable {
  /// Les agents, dans l'ordre de l'état civil, frise des contrats comprise.
  final List<StaffMember> members;

  /// Les pointages de la plage, par agent puis par jour.
  final Map<String, Map<String, StaffAttendanceRecord>> records;

  /// Jours validés et mois clos, par `kind:periodStart`.
  final Map<String, StaffAttendanceLock> locks;

  final StaffAttendanceSettings settings;

  /// L'année scolaire courante ; `null` tant que le socle n'est pas descendu.
  final StaffSchoolYear? schoolYear;

  /// Taux horaire des contrats « heures prestées », par `contractId`. Vide
  /// sans `hr.pay.read` : on n'affiche pas un montant qu'on ne peut pas voir.
  final Map<String, Money> contractRates;

  /// Le fichier des agents a-t-il déjà été reçu une fois ?
  final bool hasEverSynced;

  const StaffAttendanceSnapshot({
    required this.members,
    required this.records,
    required this.locks,
    required this.settings,
    required this.hasEverSynced,
    this.schoolYear,
    this.contractRates = const {},
  });

  static final StaffAttendanceSnapshot empty = StaffAttendanceSnapshot(
    members: const [],
    records: const {},
    locks: const {},
    settings: StaffAttendanceSettings.defaults,
    hasEverSynced: false,
  );

  static String lockKey(StaffAttendanceLockKind kind, String periodStart) =>
      '${kind.wire}:$periodStart';

  StaffAttendanceRecord? recordOf(String staffMemberId, String day) =>
      records[staffMemberId]?[day];

  StaffAttendanceLock? dayLock(String day) =>
      locks[lockKey(StaffAttendanceLockKind.day, day)];

  StaffAttendanceLock? monthLock(String month) =>
      locks[lockKey(
        StaffAttendanceLockKind.month,
        StaffWorkCalendar.firstOf(month),
      )];

  /// Le rapport du jour est validé (et le reste tant qu'il n'est pas rouvert).
  bool isDayValidated(String day) => dayLock(day)?.locked ?? false;

  bool isMonthClosed(String month) => monthLock(month)?.locked ?? false;

  /// Le jour refuse-t-il toute écriture ? Validé, ou dans un mois clos.
  bool isDayFrozen(String day) =>
      isDayValidated(day) || isMonthClosed(StaffWorkCalendar.monthOf(day));

  @override
  List<Object?> get props => [
    members,
    records,
    locks,
    settings,
    schoolYear,
    contractRates,
    hasEverSynced,
  ];
}
