import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';

void main() {
  late Database db;
  late StaffMemberDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = StaffMemberDao(db);
  });
  tearDown(() async => db.close());

  StaffMemberDeltaDto delta(Map<String, dynamic> json) =>
      StaffMemberDeltaDto.tryParse(json)!;

  test(
    "une fiche descendue s'insère, synchronisée, et se relit entière",
    () async {
      await dao.applyPulled(
        [
          delta(
            staffMemberJson(
              'm-1',
              contracts: [
                contractPeriodJson(
                  'c-1',
                  kind: 'VACATAIRE',
                  payMode: 'HEURES_PRESTEES',
                ),
              ],
            ),
          ),
        ],
        schoolId: 'school-1',
        nowMs: 1,
      );

      final member = (await dao.listForSchool('school-1')).single.toEntity();
      expect(member.staffNumber, 'CF-AG-0001');
      expect(member.fullName, 'Kalala Mutombo Jean-Pierre');
      expect(member.category, StaffCategory.teacher);
      expect(member.sex, StaffSex.male);
      expect(member.diplomas.single.title, 'Licence en mathématiques');
      expect(member.contracts.single.isHourlyVacataire, isTrue);
      expect(member.syncState, StaffSyncState.synced);
    },
  );

  test(
    'les fiches se lisent dans l ordre de l état civil, par école',
    () async {
      await dao.applyPulled(
        [
          delta(staffMemberJson('m-1', lastName: 'mbuyi')),
          delta(staffMemberJson('m-2', lastName: 'Kalala')),
        ],
        schoolId: 'school-1',
        nowMs: 1,
      );
      await dao.applyPulled(
        [delta(staffMemberJson('m-3', lastName: 'Autre'))],
        schoolId: 'school-2',
        nowMs: 1,
      );

      final names = [
        for (final row in await dao.listForSchool('school-1'))
          row.toEntity().lastName,
      ];
      expect(names, ['Kalala', 'mbuyi']);
    },
  );

  test('une fiche synchronisée prend tout ce que le serveur dit', () async {
    await dao.applyPulled(
      [delta(staffMemberJson('m-1'))],
      schoolId: 'school-1',
      nowMs: 1,
    );

    await dao.applyPulled(
      [
        delta(
          staffMemberJson('m-1', firstName: 'Jean', staffNumber: 'CF-AG-0009'),
        ),
      ],
      schoolId: 'school-1',
      nowMs: 2,
    );

    final member = (await dao.listForSchool('school-1')).single.toEntity();
    expect(member.firstName, 'Jean');
    expect(member.staffNumber, 'CF-AG-0009');
  });

  test('une saisie locale en attente garde son contenu ; le matricule et la '
      'frise arrivent quand même', () async {
    await dao.applyPulled(
      [delta(staffMemberJson('m-1', staffNumber: null))],
      schoolId: 'school-1',
      nowMs: 1,
    );
    await db.update(
      'staff_members',
      {'first_name': 'Saisi-sur-la-tablette', 'sync_status': 'PENDING_SYNC'},
      where: 'id = ?',
      whereArgs: ['m-1'],
    );

    await dao.applyPulled(
      [
        delta(
          staffMemberJson(
            'm-1',
            firstName: 'Ancien',
            staffNumber: 'CF-AG-0048',
            contracts: [contractPeriodJson('c-1')],
          ),
        ),
      ],
      schoolId: 'school-1',
      nowMs: 2,
    );

    final member = (await dao.listForSchool('school-1')).single.toEntity();
    expect(member.firstName, 'Saisi-sur-la-tablette');
    expect(member.staffNumber, 'CF-AG-0048');
    expect(member.contracts.single.kind, StaffContractKind.permanent);
    expect(member.syncState, StaffSyncState.pending);
  });

  test('sans école, rien ne s écrit', () async {
    expect(
      await dao.applyPulled(
        [delta(staffMemberJson('m-1'))],
        schoolId: '',
        nowMs: 1,
      ),
      0,
    );
    expect(await db.query('staff_members'), isEmpty);
  });
}
