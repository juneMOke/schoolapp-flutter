import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_push_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Écritures locales d'une fiche — **toujours avec leur entrée d'outbox, dans
/// la même transaction** : une fiche sans entrée ne partirait jamais, une
/// entrée sans fiche pousserait un état introuvable.
///
/// L'identifiant d'entrée est **déterministe** (`STAFF_MEMBER:<id>`) : chaque
/// enregistrement remplace l'entrée encore en attente par la fiche complète la
/// plus récente. La file garde au plus une fiche par agent, et corriger une
/// fiche refusée la remet en file d'elle-même.
class StaffMemberWriteDao {
  final Database _db;

  const StaffMemberWriteDao(this._db);

  static const String table = StaffMemberLocalModel.table;
  static const String aggregateType = 'STAFF_MEMBER';

  static String entryId(String staffMemberId) =>
      '$aggregateType:$staffMemberId';

  /// Enregistre la fiche sur le poste et la met en file.
  ///
  /// Sur une ligne existante, seuls le contenu et l'état de synchro sont
  /// réécrits : un accusé ou un pull appliqué entre la lecture de la fiche et
  /// cette écriture a pu poser un matricule ou une frise — les réécrire depuis
  /// la lecture d'avant les déferait.
  Future<void> save({
    required StaffMemberSyncRequestDto request,
    required String schoolId,
    required int nowMs,
  }) async {
    final input = request.staffMember;
    final content = <String, Object?>{
      'last_name': input.lastName,
      'middle_name': input.middleName,
      'first_name': input.firstName,
      'sex': input.sex,
      'birth_date': input.birthDate,
      'phone_number': input.phoneNumber,
      'email': input.email,
      'city': input.city,
      'district': input.district,
      'municipality': input.municipality,
      'neighborhood': input.neighborhood,
      'address': input.address,
      'category': input.category,
      'job_title': input.jobTitle,
      'entry_date': input.entryDate,
      'branches': jsonEncode(input.branches),
      'diplomas': jsonEncode([for (final d in input.diplomas) d.toJson()]),
      'client_updated_at': input.clientUpdatedAt,
      'sync_status': RecordSyncState.pending.dbValue,
      'sync_error': null,
      'sync_error_code': null,
      'updated_at': nowMs,
    };
    await _db.transaction((txn) async {
      final updated = await txn.update(
        table,
        content,
        where: 'id = ?',
        whereArgs: [input.id],
      );
      if (updated == 0) {
        await txn.insert(table, {
          'id': input.id,
          'school_id': schoolId,
          ...content,
        });
      }
      await OutboxDao(txn).enqueue(
        OutboxEntry(
          id: entryId(input.id),
          aggregateType: aggregateType,
          aggregateId: input.id,
          operation: OutboxOperation.upsert,
          payload: jsonEncode(request.toJson()),
          // Sans école, l'entrée deviendrait inéligible au flush scopé.
          schoolId: schoolId,
          createdAt: nowMs,
        ),
      );
    });
  }
}
