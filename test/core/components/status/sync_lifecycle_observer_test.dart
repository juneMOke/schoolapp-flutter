import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_lifecycle_observer.dart';

void main() {
  /// Le câblage, et rien d'autre : un état de cycle de vie entre, un appel
  /// sort. Ce test existe parce qu'un déclencheur de synchro non branché ne se
  /// voit sur aucun écran et ne fait échouer aucun test métier.
  late List<String> calls;

  setUp(() => calls = []);

  Future<void> pumpObserver(WidgetTester tester) => tester.pumpWidget(
    SyncLifecycleObserver(
      onResume: () => calls.add('resume'),
      onPause: () => calls.add('pause'),
      child: const MaterialApp(home: SizedBox.shrink()),
    ),
  );

  Future<void> send(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }

  testWidgets('un retour au premier plan déclenche onResume', (tester) async {
    await pumpObserver(tester);

    await send(tester, AppLifecycleState.resumed);

    expect(calls, ['resume']);
  });

  testWidgets(
    'tout retrait déclenche onPause, quelle qu\'en soit la profondeur',
    (tester) async {
      await pumpObserver(tester);

      // `inactive` compte comme les autres : le seul consommateur — l'arrêt du
      // battement — se rétablit d'un `Timer` recréé au retour, alors que laisser
      // tourner une boucle réseau hors de tout usage ne se rattrape pas.
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.detached,
      ]) {
        await send(tester, state);
      }

      expect(calls, ['pause', 'pause', 'pause', 'pause']);
    },
  );

  testWidgets('chaque reprise compte — l\'anti-rafale est ailleurs', (
    tester,
  ) async {
    await pumpObserver(tester);

    for (var i = 0; i < 3; i++) {
      await send(tester, AppLifecycleState.paused);
      await send(tester, AppLifecycleState.resumed);
    }

    expect(calls.where((c) => c == 'resume').length, 3);
    expect(calls.where((c) => c == 'pause').length, 3);
  });

  testWidgets('démonté, il ne reste pas abonné au cycle de vie', (
    tester,
  ) async {
    await pumpObserver(tester);

    // Sans `removeObserver` dans `dispose`, l'observateur survivrait à son
    // widget : la fuite est silencieuse et le rappel taperait un cubit fermé.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await send(tester, AppLifecycleState.resumed);
    await send(tester, AppLifecycleState.paused);

    expect(calls, isEmpty);
  });

  testWidgets('l\'enfant est rendu tel quel', (tester) async {
    await tester.pumpWidget(
      SyncLifecycleObserver(
        onResume: () {},
        onPause: () {},
        child: const MaterialApp(home: Text('contenu')),
      ),
    );

    expect(find.text('contenu'), findsOneWidget);
  });
}
