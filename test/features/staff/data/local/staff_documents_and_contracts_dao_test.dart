import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/staff/local/staff_document_type_local_model.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() async => db.close());

  test('une pièce descendue remplace la ligne de même id', () async {
    final dao = StaffDocumentDao(db);
    await dao.applyPulled(
      [StaffDocumentDeltaDto.tryParse(staffDocumentJson('d-1'))!],
      schoolId: 'school-1',
      nowMs: 1,
    );
    await dao.applyPulled(
      [StaffDocumentDeltaDto.tryParse(staffDocumentJson('d-1', code: 'DP'))!],
      schoolId: 'school-1',
      nowMs: 2,
    );

    final document = (await dao.listForSchool('school-1')).single.toEntity();
    expect(document.code, StaffDocumentCode.diploma);
    expect(document.syncState, RecordSyncState.synced);
    expect(document.isImage, isTrue);
  });

  test('un contrat descendu garde ses montants dans leur devise', () async {
    await StaffContractDao(db).applyPulled(
      [StaffContractDeltaDto.tryParse(staffContractJson('c-1'))!],
      schoolId: 'school-1',
      nowMs: 1,
    );

    final row = (await db.query('staff_contracts')).single;
    expect(row['amount_in_cents'], 32000);
    expect(row['currency'], 'USD');
    expect(row['staff_member_id'], 'm-1');
  });

  test(
    'les types de pièces se remplacent en bloc, par école, dans l ordre',
    () async {
      final dao = StaffDocumentTypeDao(db);
      StaffDocumentTypeLocalModel type(
        String code,
        int rank, {
        String school = 'school-1',
      }) => StaffDocumentTypeLocalModel(
        schoolId: school,
        code: code,
        label: code,
        alwaysRequired: code == 'ID',
        requiredFor: code == 'CT' ? const ['PERMANENT'] : const [],
        sortOrder: rank,
      );

      await dao.replaceForSchool([
        type('ID', 0),
        type('DP', 1),
      ], schoolId: 'school-1');
      await dao.replaceForSchool([
        type('ID', 0, school: 'school-2'),
      ], schoolId: 'school-2');
      await dao.replaceForSchool([
        type('CT', 0),
        type('ID', 1),
      ], schoolId: 'school-1');

      final types = await dao.forSchool('school-1');
      expect(types.map((t) => t.code), ['CT', 'ID']);
      expect(types.first.requiredFor, ['PERMANENT']);
      expect(await dao.forSchool('school-2'), hasLength(1));
    },
  );
}
