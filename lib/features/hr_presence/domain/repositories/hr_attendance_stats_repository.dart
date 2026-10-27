import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_report.dart';

/// Les statistiques de présence du personnel — **100 % serveur** (D1) :
/// tableau de bord, détail d'un agent, fiche individuelle, récapitulatif et
/// PDF lisent les pointages déjà remontés. Hors ligne, l'erreur réseau
/// s'affiche ; seul le registre du jour reste local.
abstract class HrAttendanceStatsRepository {
  /// Le tableau de bord de [window].
  Future<Either<Failure, HrAttendanceDashboard>> dashboard(
    DashboardWindow window,
  );

  /// Le mois `AAAA-MM` d'un agent.
  Future<Either<Failure, HrAttendanceAgentMonth>> agentMonth(
    String staffMemberId, {
    required String month,
  });

  /// L'année scolaire courante d'un agent.
  Future<Either<Failure, HrAttendanceAgentYear>> agentYear(
    String staffMemberId,
  );

  /// La liste de la fiche individuelle sur [scope].
  Future<Either<Failure, HrAttendanceProfiles>> profiles(HrProfileScope scope);

  /// Le récapitulatif du mois `AAAA-MM` pour la paie.
  Future<Either<Failure, HrAttendanceRecap>> recap(String month);

  /// Le PDF d'assiduité de [window], filtré par [search] comme la liste.
  Future<Either<Failure, HrAttendanceReport>> report(
    DashboardWindow window, {
    String search,
  });

  /// La liste de la fiche individuelle en PDF (pièce PR) sur [scope],
  /// filtrée comme l'écran : recherche, catégorie, profil.
  Future<Either<Failure, HrAttendanceReport>> profilesReport(
    HrProfileScope scope, {
    String search,
    StaffCategory? category,
    PresenceProfile? profile,
  });

  /// La fiche de présence d'un agent : son mois `AAAA-MM` ([month]), ou son
  /// année scolaire courante (`null`).
  Future<Either<Failure, HrAttendanceReport>> agentSheet(
    String staffMemberId, {
    String? month,
  });
}
