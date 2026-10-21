import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/startup/local_data_recovery_app.dart';

void main() {
  late int retries;
  late int resets;
  late bool resetFails;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      LocalDataRecoveryApp(
        onRetry: () async => retries++,
        onReset: () async {
          resets++;
          if (resetFails) throw StateError('disque');
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    retries = 0;
    resets = 0;
    resetFails = false;
  });

  testWidgets('Réessayer relance le démarrage', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(retries, 1);
    expect(resets, 0);
  });

  testWidgets('l effacement exige une confirmation', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Effacer les données locales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(resets, 0);

    await tester.tap(find.text('Effacer les données locales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();
    expect(resets, 1);
  });

  testWidgets('un effacement qui échoue le dit', (tester) async {
    resetFails = true;
    await pumpApp(tester);

    await tester.tap(find.text('Effacer les données locales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();

    expect(
      find.text("L'effacement a échoué. Fermez l'application et réessayez."),
      findsOneWidget,
    );
  });
}
