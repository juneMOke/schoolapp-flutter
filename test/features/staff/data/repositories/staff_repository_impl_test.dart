import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/staff/local/staff_document_type_local_model.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_write_dao.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../staff_builders.dart' show completeDraft;
import '../../staff_fixtures.dart';

void main() {
  late Database db;
  late SyncMetaDao meta;
  late CurrentUserContext user;
  late StaffRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    meta = SyncMetaDao(db);
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    repo = StaffRepositoryImpl(
      members: StaffMemberDao(db),
      writer: StaffMemberWriteDao(db),
      documents: StaffDocumentDao(db),
      types: StaffDocumentTypeDao(db),
      syncMeta: meta,
      currentUser: user,
      now: () => DateTime.utc(2026, 9, 29, 8),
    );
  });
  tearDown(() async => db.close());

  Future<StaffFileSnapshot> load() async =>
      (await repo.loadFile()).fold((f) => fail('$f'), (s) => s);

  test('un fichier jamais descendu se dit tel, même vide', () async {
    final snapshot = await load();

    expect(snapshot.members, isEmpty);
    expect(snapshot.hasEverSynced, isFalse);

    await meta.setCursor('staff_members@school-1', cursor: 'w1', syncedAt: 1);
    expect((await load()).hasEverSynced, isTrue);
  });

  test(
    'les agents se rangent Nom → Post-nom → Prénom, accents repliés',
    () async {
      await StaffMemberDao(db).applyPulled(
        [
          for (final (id, last) in [
            ('m-1', 'Zola'),
            ('m-2', 'Émongo'),
            ('m-3', 'ebale'),
          ])
            StaffMemberDeltaDto.tryParse(staffMemberJson(id, lastName: last))!,
        ],
        schoolId: 'school-1',
        nowMs: 1,
      );

      expect((await load()).members.map((m) => m.lastName), [
        'ebale',
        'Émongo',
        'Zola',
      ]);
    },
  );

  test('les pièces se regroupent par agent, et les types se typent', () async {
    await StaffDocumentDao(db).applyPulled(
      [
        StaffDocumentDeltaDto.tryParse(
          staffDocumentJson('d-1', staffMemberId: 'm-1'),
        )!,
        StaffDocumentDeltaDto.tryParse(
          staffDocumentJson('d-2', staffMemberId: 'm-1', code: 'DP'),
        )!,
        StaffDocumentDeltaDto.tryParse(
          staffDocumentJson('d-3', staffMemberId: 'm-2'),
        )!,
      ],
      schoolId: 'school-1',
      nowMs: 1,
    );
    await StaffDocumentTypeDao(db).replaceForSchool(const [
      StaffDocumentTypeLocalModel(
        schoolId: 'school-1',
        code: 'LD',
        label: 'Lettre de désignation',
        alwaysRequired: false,
        requiredFor: ['PERMANENT', 'INCONNU'],
      ),
    ], schoolId: 'school-1');

    final snapshot = await load();
    expect(snapshot.documentsByMember['m-1'], hasLength(2));
    expect(snapshot.documentsByMember['m-2'], hasLength(1));
    // Un statut que ce poste ne connaît pas est écarté, pas fatal.
    expect(snapshot.documentTypes.single.requiredFor, {
      StaffContractKind.permanent,
    });
  });

  test('sans école courante, un fichier vide', () async {
    user.set('u-1', schoolId: null);

    expect(await load(), StaffFileSnapshot.empty);
  });

  test('enregistrer écrit la fiche, en attente, avec son auteur', () async {
    final saved = await repo.saveMember(completeDraft());

    expect(saved.isRight(), isTrue);
    final found = (await repo.findMember(
      'new',
    )).fold((f) => fail('$f'), (m) => m);
    expect(found.syncState.name, 'pending');
    final entry = (await db.query('outbox')).single;
    expect(entry['payload'] as String, contains('"authorId":"u-1"'));
    expect(entry['school_id'], 'school-1');
  });

  test('sans session, ou fiche incomplète : rien n est écrit', () async {
    expect(
      (await repo.saveMember(const StaffMemberDraft(id: 'x'))).isLeft(),
      isTrue,
    );
    user.set(null, schoolId: 'school-1');
    expect((await repo.saveMember(completeDraft())).isLeft(), isTrue);
    expect(await db.query('outbox'), isEmpty);
  });
}
