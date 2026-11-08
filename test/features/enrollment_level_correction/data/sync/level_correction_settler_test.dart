import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/level_correction_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_settler.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../level_correction_fixtures.dart';

/// La garde du guichet ne se lève que sur PREUVE que les créances de la
/// nouvelle grille sont là : une descente partie après l'accusé, sans échec
/// sur les ressources qui touchent l'argent.
void main() {
  const resources = {'enrollments', 'charges', 'members'};
  const required = {'enrollments', 'charges', 'tombstones'};

  late Database db;
  late LevelCorrectionSyncDao sync;
  late LevelCorrectionReadDao reader;
  late LevelCorrectionChangeBus bus;
  late List<Set<String>> emitted;
  late List<Set<String>> pulls;
  late PullRunReport report;
  late int clock;

  LevelCorrectionSettler settler() => LevelCorrectionSettler(
    sync: sync,
    bus: bus,
    pull: (r) async {
      pulls.add(r);
      return report;
    },
    resources: resources,
    required: required,
    now: () => clock,
  );

  PullRunReport outcomes(Map<String, PullResult> o) =>
      PullRunReport(outcomes: o);

  setUp(() async {
    db = await openFullOfflineDb();
    sync = LevelCorrectionSyncDao(db);
    reader = LevelCorrectionReadDao(db);
    bus = LevelCorrectionChangeBus();
    emitted = [];
    bus.stream.listen(emitted.add);
    pulls = [];
    clock = 100;
    report = outcomes({
      'enrollments': PullResult.updated,
      'charges': PullResult.notModified,
      'tombstones': PullResult.updated,
    });
    await LevelCorrectionWriteDao(
      db,
    ).record(correctionGesture('g-1'), schoolId: kSchool, nowMs: 1);
  });
  tearDown(() => db.close());

  Future<LevelCorrectionStatus?> status() async =>
      (await reader.latestFor(kEnrollment))?.status;

  test('rien à descendre : aucun appel réseau', () async {
    await settler().settle();
    expect(pulls, isEmpty);
  });

  test('accusée, descente complète : descendue et annoncée', () async {
    await sync.markApplied('g-1', nowMs: 50);
    await settler().settle();
    await pumpEventQueue();

    expect(pulls, [resources]);
    expect(await status(), LevelCorrectionStatus.settled);
    expect(emitted, [
      {kEnrollment},
    ]);
  });

  test('les créances ont échoué : la garde tient, et le flush suivant '
      'retente', () async {
    await sync.markApplied('g-1', nowMs: 50);
    report = outcomes({
      'enrollments': PullResult.updated,
      'charges': PullResult.error,
      'tombstones': PullResult.updated,
    });
    final s = settler();
    await s.settle();
    expect(await status(), LevelCorrectionStatus.applied);
    expect(emitted, isEmpty);

    report = outcomes({
      'enrollments': PullResult.notModified,
      'charges': PullResult.updated,
      'tombstones': PullResult.notModified,
    });
    await s.settle();
    expect(pulls, hasLength(2));
    expect(await status(), LevelCorrectionStatus.settled);
  });

  test('hors ligne, ou ressource sautée : rien ne descend', () async {
    await sync.markApplied('g-1', nowMs: 50);
    report = const PullRunReport.offline();
    await settler().settle();
    expect(await status(), LevelCorrectionStatus.applied);

    report = outcomes({
      'enrollments': PullResult.updated,
      'tombstones': PullResult.updated,
    });
    await settler().settle();
    expect(await status(), LevelCorrectionStatus.applied);
  });

  test('accusée pendant la descente : attend la suivante', () async {
    await sync.markApplied('g-1', nowMs: 150);
    await settler().settle();
    expect(await status(), LevelCorrectionStatus.applied);
  });

  test('deux appels concurrents partagent une seule descente', () async {
    await sync.markApplied('g-1', nowMs: 50);
    final s = settler();
    await Future.wait([s.settle(), s.settle()]);
    expect(pulls, hasLength(1));
  });

  test('une descente qui lève ne remonte pas', () async {
    await sync.markApplied('g-1', nowMs: 50);
    final s = LevelCorrectionSettler(
      sync: sync,
      bus: bus,
      pull: (_) async => throw StateError('réseau'),
      resources: resources,
      required: required,
      now: () => clock,
    );
    await s.settle();
    expect(await status(), LevelCorrectionStatus.applied);
  });
}
