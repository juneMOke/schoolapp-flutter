import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/web/app_update/app_update_cubit.dart';
import 'package:school_app_flutter/core/web/app_update/deployed_build_source.dart';

class _Source implements DeployedBuildSource {
  final List<String?> answers;
  int reads = 0;

  _Source(this.answers);

  @override
  Future<String?> read() async =>
      answers[(reads++).clamp(0, answers.length - 1)];
}

void main() {
  late StreamController<void> ticks;

  setUp(() => ticks = StreamController<void>());
  tearDown(() => ticks.close());

  Future<AppUpdateCubit> started(_Source source) async {
    final cubit = AppUpdateCubit(source: source, ticks: ticks.stream);
    addTearDown(cubit.close);
    await cubit.start();
    return cubit;
  }

  Future<void> tick() async {
    ticks.add(null);
    await pumpEventQueue();
  }

  test('même version déployée : rien à proposer', () async {
    final source = _Source(['1.0.0+1']);
    final cubit = await started(source);
    await tick();
    await tick();
    expect(cubit.state, isFalse);
    expect(source.reads, 3);
  });

  test('un nouveau déploiement est vu au passage suivant, puis on cesse de '
      'regarder', () async {
    final source = _Source(['1.0.0+1', '1.0.0+1', '1.0.1+2']);
    final cubit = await started(source);
    await tick();
    expect(cubit.state, isFalse);
    await tick();
    expect(cubit.state, isTrue);
    await tick();
    expect(source.reads, 3);
  });

  test('une lecture qui échoue ne conclut rien', () async {
    final cubit = await started(_Source(['1.0.0+1', null, '1.0.0+1']));
    await tick();
    await tick();
    expect(cubit.state, isFalse);
  });

  test('hors ligne à l\'ouverture : la première lecture réussie sert de '
      'référence', () async {
    final cubit = await started(_Source([null, '1.0.0+1', '1.0.0+1']));
    await tick();
    await tick();
    expect(cubit.state, isFalse);
  });
}
