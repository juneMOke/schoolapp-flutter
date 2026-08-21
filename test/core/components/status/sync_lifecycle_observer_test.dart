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

  testWidgets('un vrai retrait de l\'écran déclenche onPause', (tester) async {
    await pumpObserver(tester);

    for (final state in const [
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      await send(tester, state);
    }

    expect(calls, ['pause', 'pause', 'pause']);
  });

  testWidgets('`inactive` n\'appelle RIEN', (tester) async {
    // État de recouvrement transitoire — volet de notifications, boîte de
    // permission (le chemin ESC/POS en demande), feuille de partage, sélecteur
    // de fichiers, focus en écran partagé. L'application est toujours là.
    //
    // Le traiter comme un retrait coupait le battement, et le retour le
    // recréait avec un compte à rebours neuf : un caissier qui franchit cette
    // frontière plus souvent que la période ne recevait plus AUCUN tic, donc
    // plus aucun push ni pull périodique, pendant que le drapeau d'armement
    // affichait « actif ».
    await pumpObserver(tester);

    for (var i = 0; i < 5; i++) {
      await send(tester, AppLifecycleState.inactive);
      await send(tester, AppLifecycleState.resumed);
    }

    // Les reprises sont bien rapportées ; aucune pause ne s'est glissée entre.
    expect(calls, List.filled(5, 'resume'));
  });

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
