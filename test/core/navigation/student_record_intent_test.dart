import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/leave_replayed_route.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';

void main() {
  const intent = FacturationCreatePaymentIntent(
    studentId: 'eleve-x',
    academicYearId: 'annee-1',
    firstName: 'Grâce',
    lastName: 'Tshala',
    surname: '',
    levelName: '6e',
    levelGroupName: 'Primaire',
    studentCharges: [],
  );

  group('extraForRecord (par fromRouteContext)', () {
    test('l\'extra de cette adresse est rendu tel quel', () {
      final read = FacturationCreatePaymentIntent.fromRouteContext(
        studentId: 'eleve-x',
        academicYearId: 'annee-1',
        extra: intent,
      );
      expect(identical(read, intent), isTrue);
    });

    test('l\'extra d\'un autre élève est refusé : la fiche repart de son '
        'adresse', () {
      final read = FacturationCreatePaymentIntent.fromRouteContext(
        studentId: 'eleve-y',
        academicYearId: 'annee-1',
        extra: intent,
      );
      expect(read.studentId, 'eleve-y');
      expect(read.hasDisplayContext, isFalse);
    });
  });

  test('un encaissement écrit est consommé ; une autre intention, non', () {
    const other = FacturationCreatePaymentIntent(
      studentId: 'eleve-z',
      academicYearId: 'annee-1',
      firstName: 'A',
      lastName: 'B',
      surname: '',
      levelName: '',
      levelGroupName: '',
      studentCharges: [],
    );
    final written = FacturationCreatePaymentIntent.fromRouteContext(
      studentId: 'eleve-z',
      academicYearId: 'annee-1',
      extra: other,
    )..markSpent();
    expect(other.isSpent, isTrue);
    expect(written.isSpent, isTrue);
    expect(intent.isSpent, isFalse);
  });

  testWidgets('une page rejouée par l\'historique s\'efface vers celle '
      'd\'en dessous', (tester) async {
    final router = GoRouter(
      initialLocation: '/fiche',
      routes: [
        GoRoute(
          path: '/fiche',
          builder: (_, _) => const Text('fiche'),
          routes: [
            GoRoute(
              path: 'encaissement',
              builder: (_, _) =>
                  const LeaveReplayedRoute(fallbackLocation: '/fiche'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/fiche/encaissement');
    await tester.pumpAndSettle();
    expect(find.text('fiche'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('rien dessous : elle rejoint son adresse de repli', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/fiche/encaissement',
      routes: [
        GoRoute(
          path: '/fiche',
          builder: (_, _) => const Text('fiche'),
          routes: [
            GoRoute(
              path: 'encaissement',
              builder: (_, _) =>
                  const LeaveReplayedRoute(fallbackLocation: '/fiche'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/fiche');
  });
}
