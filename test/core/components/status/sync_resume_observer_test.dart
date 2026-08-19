import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_resume_observer.dart';

void main() {
  /// Le câblage, et rien d'autre : un `resumed` entre, un appel sort. Ce test
  /// existe parce qu'un déclencheur de synchro non branché ne se voit sur aucun
  /// écran et ne fait échouer aucun test métier.
  Future<void> pumpObserver(WidgetTester tester, VoidCallback onResume) =>
      tester.pumpWidget(
        SyncResumeObserver(
          onResume: onResume,
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );

  testWidgets('un retour au premier plan déclenche le rappel', (tester) async {
    var calls = 0;
    await pumpObserver(tester, () => calls++);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(calls, 1);
  });

  testWidgets('les autres transitions ne déclenchent rien', (tester) async {
    var calls = 0;
    await pumpObserver(tester, () => calls++);

    // `inactive` encadre chaque transition — et, sur iOS, la simple ouverture
    // du centre de contrôle. Y réagir lancerait un cycle pour une notification
    // balayée.
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }

    expect(calls, 0);
  });

  testWidgets('chaque reprise compte — l\'anti-rafale est ailleurs', (
    tester,
  ) async {
    var calls = 0;
    await pumpObserver(tester, () => calls++);

    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    }

    expect(calls, 3);
  });

  testWidgets('démonté, il ne reste pas abonné au cycle de vie', (
    tester,
  ) async {
    var calls = 0;
    await pumpObserver(tester, () => calls++);

    // Sans `removeObserver` dans `dispose`, l'observateur survivrait à son
    // widget : la fuite est silencieuse et le rappel taperait un cubit fermé.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('l\'enfant est rendu tel quel', (tester) async {
    await tester.pumpWidget(
      SyncResumeObserver(
        onResume: () {},
        child: const MaterialApp(home: Text('contenu')),
      ),
    );

    expect(find.text('contenu'), findsOneWidget);
  });
}
