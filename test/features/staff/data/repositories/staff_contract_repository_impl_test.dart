import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_contract_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';

const _draft = StaffContractDraft(
  kind: StaffContractKind.vacataire,
  payMode: StaffPayMode.hourly,
  effectiveFrom: '2026-11-01',
  amount: '5,50',
);

void main() {
  late Database db;
  late CurrentUserContext user;
  late StaffContractRepositoryImpl repo;
  late StaffRepositoryImpl file;

  setUp(() async {
    db = await openFullOfflineDb();
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    repo = StaffContractRepositoryImpl(
      contracts: StaffContractDao(db),
      writer: StaffContractWriteDao(db),
      currentUser: user,
      ids: const IdGenerator(Uuid()),
      now: () => DateTime.utc(2026, 9, 29, 8),
    );
    file = StaffRepositoryImpl(
      members: StaffMemberDao(db),
      contracts: StaffContractDao(db),
      writer: StaffMemberWriteDao(db),
      documents: StaffDocumentDao(db),
      types: StaffDocumentTypeDao(db),
      syncMeta: SyncMetaDao(db),
      currentUser: user,
    );
    await StaffMemberDao(db).applyPulled(
      [
        StaffMemberDeltaDto.tryParse(
          staffMemberJson(
            'm-1',
            contracts: [contractPeriodJson('c-0', effectiveFrom: '2025-09-01')],
          ),
        )!,
      ],
      schoolId: 'school-1',
      nowMs: 1,
    );
  });
  tearDown(() async => db.close());

  Future<List<StaffContract>> contracts() async =>
      (await repo.contractsOf('m-1')).fold((f) => fail('$f'), (c) => c);

  test('poser écrit en centimes, en attente, et la frise le montre', () async {
    expect((await repo.addContract('m-1', _draft)).isRight(), isTrue);

    final posed = (await contracts()).single;
    expect(posed.amount!.amountInCents, 550);
    expect(posed.payMode, StaffPayMode.hourly);
    expect(posed.syncState, StaffSyncState.pending);
    expect(await OutboxDao(db).pendingAll(), hasLength(1));

    final member = (await file.findMember(
      'm-1',
    )).fold((f) => fail('$f'), (m) => m);
    expect(member.contracts.map((p) => p.contractId), ['c-0', posed.id]);
    final listed = (await file.loadFile()).fold((f) => fail('$f'), (s) => s);
    expect(listed.members.single.contracts, member.contracts);
  });

  test(
    'corriger : l original sort de la frise, le remplaçant y entre',
    () async {
      await StaffContractDao(db).applyPulled(
        [StaffContractDeltaDto.tryParse(staffContractJson('c-0'))!],
        schoolId: 'school-1',
        nowMs: 1,
      );
      final original = (await contracts()).single;

      final written = await repo.correctContract(
        original,
        reason: ' Mauvais statut ',
        replacement: _draft,
      );

      expect(written.isRight(), isTrue);
      final member = (await file.findMember(
        'm-1',
      )).fold((f) => fail('$f'), (m) => m);
      expect(member.contracts.single.kind, StaffContractKind.vacataire);
      expect(
        (await OutboxDao(db).pendingAll()).single.payload,
        contains('"reason":"Mauvais statut"'),
      );

      // Une période déjà en correction ne se corrige pas deux fois.
      final again = (await contracts()).firstWhere((c) => c.id == 'c-0');
      expect(
        (await repo.correctContract(
          again,
          reason: 'x',
        )).fold((f) => f, (_) => null),
        isA<ValidationFailure>(),
      );
    },
  );

  test('sans session, rien n est écrit', () async {
    user.clear();

    final written = await repo.addContract('m-1', _draft);

    expect(written.fold((f) => f, (_) => null), isA<AuthFailure>());
    expect(await OutboxDao(db).pendingAll(), isEmpty);
  });
}
