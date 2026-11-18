import 'dart:convert';

import 'package:school_app_flutter/core/database/projections/enrollment_level_correction_sql.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_paid_check.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le serveur corrige-t-il le niveau d'un élève qui a déjà payé ?
///
/// **`false` tant que le lot F3 du back n'est pas en prod** : il refuse encore
/// en `LEVEL_CORRECTION_HAS_PAYMENTS`, et la tablette le devance. Le back
/// prévient au déploiement ; passer alors à `true` remplace ce refus par le
/// contrôle du payé ([levelCorrectionPaidRefusal]).
const bool kLevelCorrectionAcceptsPaidStudents = false;

/// Issue d'une demande de correction, vue de la tablette.
enum LevelCorrectionRecordOutcome {
  /// Le geste est posé, et part par l'outbox.
  recorded,

  /// Une correction de la même inscription attend déjà — en file, ou accusée
  /// mais pas encore descendue : rien n'est écrit.
  alreadyPending,

  /// L'élève a un versement sur l'année, même annulé : le serveur refuserait
  /// en `LEVEL_CORRECTION_HAS_PAYMENTS` (premier temps). Rien n'est écrit.
  hasPayments(LevelCorrectionRefusal.hasPayments),

  /// Une nature payée dépasse ce que le niveau cible demande. Rien n'est écrit.
  overpaid(LevelCorrectionRefusal.overpaid),

  /// Une nature payée manque au niveau cible. Rien n'est écrit.
  feeCodeAbsent(LevelCorrectionRefusal.feeCodeAbsent),

  /// Une nature payée change de devise au niveau cible. Rien n'est écrit.
  currencyChanged(LevelCorrectionRefusal.currencyChanged);

  const LevelCorrectionRecordOutcome([this.refusal]);

  /// Le refus que la tablette devance, `null` si le geste est posé ou attend.
  final LevelCorrectionRefusal? refusal;

  static LevelCorrectionRecordOutcome _of(LevelCorrectionRefusal refusal) =>
      values.firstWhere((o) => o.refusal == refusal);
}

/// Écriture d'une correction de niveau — **la ligne et son entrée d'outbox dans
/// une seule transaction** : le geste existe en entier ou pas du tout.
///
/// Une entrée par geste (`ENROLLMENT_LEVEL_CORRECTION:<id du geste>`), jamais
/// remplacée, rattachée à l'inscription (`aggregate_id`) pour que le handler
/// garde l'ordre des gestes d'un même élève.
class LevelCorrectionWriteDao {
  final Database _db;

  /// Voir [kLevelCorrectionAcceptsPaidStudents] ; les tests l'ouvrent.
  final bool _acceptsPaidStudents;

  const LevelCorrectionWriteDao(
    this._db, {
    bool acceptsPaidStudents = kLevelCorrectionAcceptsPaidStudents,
  }) : _acceptsPaidStudents = acceptsPaidStudents;

  static const String table = EnrollmentLevelCorrectionSql.table;
  static const String aggregateType =
      EnrollmentLevelCorrectionSql.aggregateType;

  static String entryId(String gestureId) => '$aggregateType:$gestureId';

  /// Code rangé sur une correction dont l'envoi avait été abandonné par la
  /// file, et qu'une nouvelle correction remplace. Si l'entrée est relancée
  /// plus tard, le handler la trouve jugée et ne l'envoie pas.
  static const String supersededCode = 'SUPERSEDED_AFTER_ABANDON';

  /// Pose [gesture], sauf si une correction de la même inscription attend déjà
  /// (la seconde partirait sur un niveau de départ périmé et tomberait en
  /// `STALE_LEVEL`) ou si le serveur refuserait à coup sûr à cause de ce que
  /// l'élève a déjà payé.
  ///
  /// Ce dernier contrôle dépend du serveur ([kLevelCorrectionAcceptsPaidStudents]) :
  /// - **premier temps** : tout versement sur l'année refuse
  ///   ([LevelCorrectionRecordOutcome.hasPayments]). Un versement **annulé**
  ///   compte aussi : le serveur le compte (décision du lot C1 du back), car
  ///   l'annulation laisse sa trace dans les pièces ;
  /// - **après F3** : seul le payé de chaque nature est jugé contre la grille
  ///   cible ([levelCorrectionPaidRefusal]).
  ///
  /// « Attend » : en file, ou accusée sans que la descente ait ramené le
  /// nouveau niveau. Une correction en attente dont l'envoi a été **abandonné**
  /// par la file ne bloque pas : elle est close ([supersededCode]) et la
  /// nouvelle prend sa place — sinon l'élève resterait sans issue.
  ///
  /// Le second contrôle ne remplace pas la garde du serveur : un versement pris
  /// sur une autre tablette n'est pas encore ici. Il épargne seulement au
  /// guichet un geste dont le refus est certain.
  Future<LevelCorrectionRecordOutcome> record(
    LevelCorrectionGesture gesture, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final open = await txn.rawQuery(
      '''
      SELECT c.id, c.sync_status,
             ${EnrollmentLevelCorrectionSql.queued('c')} AS queued
      FROM $table c
      WHERE c.enrollment_id = ?
        AND (c.sync_status = ?
          OR (c.sync_status = ? AND c.settled_at IS NULL))
      ''',
      [
        gesture.enrollmentId,
        RecordSyncState.pending.dbValue,
        RecordSyncState.synced.dbValue,
      ],
    );
    final abandoned = <String>[];
    for (final row in open) {
      final stalled =
          row['sync_status'] == RecordSyncState.pending.dbValue &&
          row['queued'] == 0;
      if (!stalled) return LevelCorrectionRecordOutcome.alreadyPending;
      abandoned.add(row['id']! as String);
    }
    final refusal = await _paidRefusal(txn, gesture);
    if (refusal != null) return LevelCorrectionRecordOutcome._of(refusal);
    for (final id in abandoned) {
      await txn.update(
        table,
        {
          'sync_status': RecordSyncState.failed.dbValue,
          'sync_error_code': supersededCode,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await txn.insert(table, {
      'id': gesture.id,
      'school_id': schoolId,
      'enrollment_id': gesture.enrollmentId,
      'student_id': gesture.studentId,
      'academic_year_id': gesture.academicYearId,
      'from_school_level_id': gesture.fromSchoolLevelId,
      'to_school_level_id': gesture.toSchoolLevelId,
      'to_school_level_group_id': gesture.toSchoolLevelGroupId,
      'to_classroom_id': gesture.toClassroomId,
      'reason': gesture.reason,
      'corrected_at': gesture.correctedAt,
      'corrected_by': gesture.authorId,
      'sync_status': RecordSyncState.pending.dbValue,
      'updated_at': nowMs,
    });
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: entryId(gesture.id),
        aggregateType: aggregateType,
        aggregateId: gesture.enrollmentId,
        operation: OutboxOperation.create,
        payload: jsonEncode(gesture.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
    return LevelCorrectionRecordOutcome.recorded;
  });

  Future<LevelCorrectionRefusal?> _paidRefusal(
    Transaction txn,
    LevelCorrectionGesture gesture,
  ) async {
    if (_acceptsPaidStudents) {
      return levelCorrectionPaidRefusal(
        txn,
        studentId: gesture.studentId,
        academicYearId: gesture.academicYearId,
        toSchoolLevelId: gesture.toSchoolLevelId,
        toSchoolLevelGroupId: gesture.toSchoolLevelGroupId,
      );
    }
    final payments = await txn.rawQuery(
      'SELECT 1 FROM payments p '
      'WHERE p.student_id = ? AND p.academic_year_id = ? '
      'LIMIT 1',
      [gesture.studentId, gesture.academicYearId],
    );
    return payments.isEmpty ? null : LevelCorrectionRefusal.hasPayments;
  }
}
