import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// Chaque flux de pull keyset possède sa propre clé `resource` dans
/// `sync_meta` (curseur + `synced_at`). Ce test garantit qu'aucune de ces
/// clés statiques n'est dupliquée entre deux flux distincts — une collision
/// ferait partager un curseur à deux pulls indépendants (cf. régression
/// corrigée par le split classrooms/classroom_members, commit 70f63bd).
///
/// `finance_ledger:{studentId}` (FinanceLedgerRefresher._resource, préfixe non
/// exposé publiquement) est répliqué ici en dur : à garder synchronisé avec
/// lib/features/finance/offline/data/sync/finance_ledger_refresher.dart.
void main() {
  test('les clés resource statiques de sync_meta sont toutes uniques', () {
    final keysByOwner = <String, String>{
      'kAttendanceResource': kAttendanceResource,
      'kAttendanceBootstrapResource': kAttendanceBootstrapResource,
      'kDisciplinaryResource': kDisciplinaryResource,
      'kDisciplinaryBootstrapResource': kDisciplinaryBootstrapResource,
      'kClassroomsResource': kClassroomsResource,
      'kClassroomMembersResource': kClassroomMembersResource,
      'kClassroomTransfersResource': kClassroomTransfersResource,
      'kClassroomTransfersBootstrapResource':
          kClassroomTransfersBootstrapResource,
      'kAcademicsCoursResourcePrefix': kAcademicsCoursResourcePrefix,
      'kAcademicsCoursBootstrapPrefix': kAcademicsCoursBootstrapPrefix,
      'kAcademicsEvaluationsResourcePrefix':
          kAcademicsEvaluationsResourcePrefix,
      'kAcademicsNotesResourcePrefix': kAcademicsNotesResourcePrefix,
      'kGradesReferentialResource': kGradesReferentialResource,
      'kScheduleTimeSlotsResource': kScheduleTimeSlotsResource,
      'kScheduleTimeSlotsBootstrap': kScheduleTimeSlotsBootstrap,
      'kScheduleSessionsResource': kScheduleSessionsResource,
      'kScheduleSessionsBootstrap': kScheduleSessionsBootstrap,
      'EnrollmentPullRepositoryImpl.referentialResource':
          EnrollmentPullRepositoryImpl.referentialResource,
      'EnrollmentPullRepositoryImpl.cohortResource':
          EnrollmentPullRepositoryImpl.cohortResource,
      'EnrollmentPullRepositoryImpl.preEnrollmentsResource':
          EnrollmentPullRepositoryImpl.preEnrollmentsResource,
      'EnrollmentPullRepositoryImpl.deltaResource':
          EnrollmentPullRepositoryImpl.deltaResource,
      'EnrollmentPullRepositoryImpl.snapshotsResource':
          EnrollmentPullRepositoryImpl.snapshotsResource,
      'FinancePullRepositoryImpl.chargesResource':
          FinancePullRepositoryImpl.chargesResource,
      'FinancePullRepositoryImpl.paymentsResource':
          FinancePullRepositoryImpl.paymentsResource,
      // Préfixe non exposé (méthode privée) — répliqué en dur, cf. docstring.
      'FinanceLedgerRefresher._resource (préfixe)': 'finance_ledger',
    };

    final seen = <String, List<String>>{};
    for (final entry in keysByOwner.entries) {
      seen.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    final collisions = Map.fromEntries(
      seen.entries.where((e) => e.value.length > 1),
    );

    expect(
      collisions,
      isEmpty,
      reason:
          'Clés resource sync_meta dupliquées entre flux distincts : '
          '$collisions',
    );
  });
}
