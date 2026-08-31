import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Réconciliation locale à partir de la réponse serveur (contrat
/// `EnrollmentAggregateResponse`) : remap canonique au succès (201/200) et
/// bascule SYNC_ERROR au rejet de validation (422).
class EnrollmentAckDao {
  final Database _db;

  const EnrollmentAckDao(this._db);

  /// Applique la réponse canonique du commit (201/200) dans une transaction :
  /// matricule, parent provisoire→canonique dans `parents` ET
  /// `student_parent`, document PROV→DEFINITIVE, sync_status=SYNCED.
  /// [enrollmentId] = id client poussé (corrélation ; absent du corps de réponse).
  Future<void> applyEnrollmentAck(
    EnrollmentAggregateResponse response, {
    required String enrollmentId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      // Élève : matricule + SYNCED.
      await _studentAck(txn, enrollmentId, response, nowMs);

      // Parents : remap provisoire → canonique dans parents ET student_parent.
      await _parentAck(response, txn, nowMs);

      // Document : PROV-… → DEFINITIVE (numéro scellé serveur).
      await _documentAck(response, txn, enrollmentId);

      // Inscription : SYNCED (+ code / statut serveur).
      await _enrollmentAck(txn, nowMs, response, enrollmentId);

      // Réductions réellement gravées (ADR-021 V1).
      await _reductionAck(txn, nowMs, response, enrollmentId);
    });
  }

  Future<void> _documentAck(
    EnrollmentAggregateResponse response,
    Transaction txn,
    String enrollmentId,
  ) async {
    if (response.documents.isNotEmpty) {
      final doc = response.documents.first;
      await txn.update(
        'generated_documents',
        {'number': doc.documentNumber, 'status': 'DEFINITIVE'},
        where: 'enrollment_id = ? AND doc_domain = ?',
        whereArgs: [enrollmentId, 'ENROLLMENT'],
      );
    }
  }

  Future<void> _enrollmentAck(
    Transaction txn,
    int nowMs,
    EnrollmentAggregateResponse response,
    String enrollmentId,
  ) async {
    await txn.update(
      'enrollments',
      {
        'sync_status': SyncState.synced.dbValue,
        'synced_at': nowMs,
        'sync_error': null,
        if (response.enrollment.enrollmentCode != null)
          'enrollment_code': response.enrollment.enrollmentCode,
        if (response.enrollment.status != null)
          'status': response.enrollment.status,
      },
      where: 'id = ?',
      whereArgs: [enrollmentId],
    );
  }

  /// Ce que le serveur a RÉELLEMENT gravé remplace ce qu'on a déclaré.
  ///
  /// Il a pu refuser un code qui avait quitté le barème pendant que la tablette
  /// était hors ligne. Garder la déclaration ferait afficher au guichet une
  /// réduction que personne n'a accordée — et le pull suivant, lui, dirait la
  /// vérité : deux écrans contradictoires à quelques minutes d'intervalle.
  ///
  /// Section absente (`null`) = accusé d'un serveur antérieur au champ : on
  /// garde la déclaration locale, faute de mieux. Elle repartira telle quelle
  /// au prochain push, et le pull la corrigera quand le serveur saura en
  /// parler.
  Future<void> _reductionAck(
    Transaction txn,
    int nowMs,
    EnrollmentAggregateResponse response,
    String enrollmentId,
  ) async {
    final codes = response.reductionCodes;
    if (codes == null) return;

    await txn.delete(
      'enrollment_reductions',
      where: 'enrollment_id = ?',
      whereArgs: [enrollmentId],
    );
    for (final code in codes.toSet()) {
      await txn.insert('enrollment_reductions', {
        'enrollment_id': enrollmentId,
        'reduction_code': code,
        'updated_at': nowMs,
      });
    }
  }

  Future<void> _parentAck(
    EnrollmentAggregateResponse response,
    Transaction txn,
    int nowMs,
  ) async {
    for (final p in response.parents) {
      if (p.providedId == p.canonicalId) {
        await txn.update(
          'parents',
          {'sync_status': SyncState.synced.dbValue, 'synced_at': nowMs},
          where: 'id = ?',
          whereArgs: [p.canonicalId],
        );
        continue;
      }
      final canonicalExists = await txn.query(
        'parents',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [p.canonicalId],
        limit: 1,
      );
      if (canonicalExists.isNotEmpty) {
        // Le canonique existe déjà (fratrie déjà synchro) : on repointe le
        // lien et on supprime le provisoire.
        await txn.rawUpdate(
          'UPDATE OR REPLACE student_parent SET parent_id = ? '
          'WHERE parent_id = ?',
          [p.canonicalId, p.providedId],
        );
        await txn.delete('parents', where: 'id = ?', whereArgs: [p.providedId]);
      } else {
        await txn.update(
          'parents',
          {
            'id': p.canonicalId,
            'sync_status': SyncState.synced.dbValue,
            'synced_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [p.providedId],
        );
        await txn.rawUpdate(
          'UPDATE OR REPLACE student_parent SET parent_id = ? '
          'WHERE parent_id = ?',
          [p.canonicalId, p.providedId],
        );
      }
    }
  }

  Future<void> _studentAck(
    Transaction txn,
    String enrollmentId,
    EnrollmentAggregateResponse response,
    int nowMs,
  ) async {
    final rows = await txn.query(
      'enrollments',
      columns: ['student_id'],
      where: 'id = ?',
      whereArgs: [enrollmentId],
      limit: 1,
    );
    final studentId = rows.isNotEmpty
        ? rows.first['student_id'] as String
        : response.student.id;
    await txn.update(
      'students',
      {
        if (response.student.matriculationNumber != null)
          'matriculation_number': response.student.matriculationNumber,
        // L'e-mail attribué à l'ACK n'est plus recopié (ADR-015 F8, schéma v27) :
        // personne ne le relisait — contrairement au matricule juste au-dessus,
        // qui remonte jusqu'au ticket imprimé. Une colonne restée NULL, c'est
        // exactement l'état voulu.
        'sync_status': SyncState.synced.dbValue,
        'synced_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  /// Rejet de validation (HTTP 422) : passe l'inscription et son élève en
  /// SYNC_ERROR (terminal, non rejoué jusqu'à correction + re-push).
  Future<void> markEnrollmentSyncError(
    String enrollmentId,
    String message, {
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      await txn.update(
        'enrollments',
        {
          'sync_status': SyncState.syncError.dbValue,
          'sync_error': message,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [enrollmentId],
      );
      final rows = await txn.query(
        'enrollments',
        columns: ['student_id'],
        where: 'id = ?',
        whereArgs: [enrollmentId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        await txn.update(
          'students',
          {'sync_status': SyncState.syncError.dbValue},
          where: 'id = ?',
          whereArgs: [rows.first['student_id']],
        );
      }
    });
  }
}
