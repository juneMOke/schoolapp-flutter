import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_database.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'offline_full_test_db.dart';

class _Online implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

class _Handler implements PullHandler {
  _Handler(this.resource, {this.onPull});

  @override
  final String resource;

  @override
  List<Perm> get requiredPermissions => const [];

  @override
  bool get isBaseline => true;

  final Future<void> Function()? onPull;
  int calls = 0;

  @override
  Future<PullOutcome> pull() async {
    calls++;
    await onPull?.call();
    return const PullOutcome.updated();
  }
}

/// Un cycle de pull est lié à l'école attachée à son départ
/// (MULTI_ECOLE_PLAN.md §10.1).
void main() {
  late Database schoolA;
  late Database schoolB;
  late TenantDatabase tenant;

  setUp(() async {
    schoolA = await openFullOfflineDb();
    schoolB = await openFullOfflineDb();
    tenant = TenantDatabase()..attach('school-a', schoolA);
  });

  tearDown(() async {
    await schoolA.close();
    await schoolB.close();
  });

  PullCoordinator coordinator(List<PullHandler> handlers) {
    final c = PullCoordinator(connectivity: _Online(), scope: tenant);
    for (final h in handlers) {
      c.registerHandler(h);
    }
    return c;
  }

  test('sans bascule, chaque flux part', () async {
    final first = _Handler('first');
    final second = _Handler('second');

    final report = await coordinator([first, second]).pullAll();

    expect([first.calls, second.calls], [1, 1]);
    expect(report.skipped, isFalse);
  });

  test('l école change pendant le cycle : les flux suivants ne tirent pas '
      'pour l école précédente', () async {
    final first = _Handler(
      'first',
      onPull: () async => tenant.attach('school-b', schoolB),
    );
    final second = _Handler('second');

    final report = await coordinator([first, second]).pullAll();

    expect(second.calls, 0);
    expect(report.skipped, isTrue);
  });

  test('la page de A arrivée après la bascule ne s écrit pas chez B', () async {
    final first = _Handler(
      'first',
      onPull: () async {
        tenant.detach();
        tenant.attach('school-b', schoolB);
        // Ce qu'un dépôt de pull ferait de sa réponse : l'appliquer, puis
        // avancer son curseur.
        await tenant.insert('sync_meta', {
          'resource': 'enrollments',
          'cursor': 'curseur-de-a',
        });
      },
    );

    await coordinator([first]).pullAll();

    expect(await schoolB.query('sync_meta'), isEmpty);
    expect(await schoolA.query('sync_meta'), isEmpty);
  });

  test('pullSubset est lié de la même façon — le chemin des écrans', () async {
    final first = _Handler(
      'first',
      onPull: () async => tenant.attach('school-b', schoolB),
    );
    final second = _Handler('second');

    final report = await coordinator([
      first,
      second,
    ]).pullSubset({'first', 'second'});

    expect(second.calls, 0);
    expect(report.skipped, isTrue);
  });
}
