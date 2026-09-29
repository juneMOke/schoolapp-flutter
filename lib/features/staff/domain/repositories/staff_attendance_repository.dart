import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';

/// Ressources (`PullHandler.resource`) des deux flux du Pointage, rangées
/// comme celles du fichier sous `<ressource>@<école>`.
const String kStaffAttendanceResource = 'staff_attendance';
const String kStaffAttendanceLocksResource = 'staff_attendance_locks';

/// Refus locaux, avant toute écriture : le jour est validé, ou le mois clos.
/// Mêmes codes que le serveur, pour un seul message à l'écran.
const String kStaffDayLockedCode = 'DAY_LOCKED';
const String kStaffMonthClosedCode = 'MONTH_CLOSED';

/// Le Pointage sur la tablette : lecture 100 % locale, écriture 100 % file
/// d'envoi.
abstract class StaffAttendanceRepository {
  /// Agents, pointages des jours [from] → [to] (inclus, `YYYY-MM-DD`),
  /// verrous et réglages.
  Future<Either<Failure, StaffAttendanceSnapshot>> load({
    required String from,
    required String to,
  });

  /// Écrit des pointages (un, ou le lot de « Restants présents ») et les met
  /// en file, chacun sous son identifiant. Refuse, sans rien écrire, un jour
  /// figé ([kStaffDayLockedCode], [kStaffMonthClosedCode]).
  Future<Either<Failure, Unit>> saveRecords(
    List<StaffAttendanceRecord> records,
  );

  /// Pose un geste de verrou sur [periodStart] (le jour, ou le 1er du mois).
  Future<Either<Failure, Unit>> recordGesture(
    StaffAttendanceGesture gesture,
    String periodStart,
  );

  Future<Either<Failure, Unit>> saveSettings(StaffAttendanceSettings settings);
}
