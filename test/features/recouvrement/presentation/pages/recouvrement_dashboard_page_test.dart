import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_buttons.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/perimeter/recovery_dashboard_perimeter.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/states/recovery_results_error_state.dart';

import '../../fixtures/recovery_fixtures.dart';
import 'recouvrement_dashboard_page_harness.dart';

/// Le tableau de bord du Recouvrement v2 monté entier : une question, portée
/// par l'adresse, posée une fois au serveur (R14), et ses états.
void main() {
  late DashboardHarness h;

  setUpAll(DashboardHarness.registerFallbacks);

  setUp(() {
    h = DashboardHarness()..setUp();
  });

  tearDown(() => h.tearDown());

  testWidgets('premier rendu : la question part avec le premier frais du '
      'catalogue, et l\'adresse le retient', (tester) async {
    await h.pump(tester);

    final asked = h.askedQuestions();
    expect(asked, hasLength(1));
    expect(asked.single, const RecoveryQuestion(feeCodes: ['TUITION']));
    expect(h.address['frais'], 'TUITION');
    final students = h.askedStudents();
    expect(students.single.tab, RecoveryTab.toChase);
    expect(students.single.page, 0);
    // En ligne, les exports sont offerts (témoin du cas hors ligne).
    expect(find.textContaining('Hors ligne'), findsNothing);
    expect(
      tester
          .widgetList<RecoveryFormatButtons>(find.byType(RecoveryFormatButtons))
          .any((b) => b.enabled),
      isTrue,
    );
  });

  testWidgets('A1 : l\'adresse rouvre exactement la même question', (
    tester,
  ) async {
    await h.pump(
      tester,
      query:
          'frais=TUITION&perimetre=cycle:g1&regle=tout-solde&onglet=tous'
          '&seuil=70',
    );

    expect(h.askedQuestions(), const [
      RecoveryQuestion(
        feeCodes: ['TUITION'],
        scope: RecoveryScopeKind.cycle,
        scopeId: 'g1',
        rule: RecoveryRuleKind.fullySettled,
      ),
    ]);
    final students = h.askedStudents().single;
    expect(students.tab, RecoveryTab.all);
    expect(students.question.scopeId, 'g1');
    expect(students.page, 0);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 70);
    expect(h.address, {
      'frais': 'TUITION',
      'perimetre': 'cycle:g1',
      'regle': 'tout-solde',
      'onglet': 'tous',
      'seuil': '70',
    });
  });

  testWidgets('un frais inconnu de l\'adresse est écarté', (tester) async {
    await h.pump(tester, query: 'frais=GHOST,SUPPLIES');

    expect(h.askedQuestions().single.feeCodes, ['SUPPLIES']);
    expect(h.address['frais'], 'SUPPLIES');
  });

  testWidgets('aucun frais connu dans l\'adresse : le premier du catalogue', (
    tester,
  ) async {
    await h.pump(tester, query: 'frais=GHOST');

    expect(h.askedQuestions().single.feeCodes, ['TUITION']);
    expect(h.address['frais'], 'TUITION');
  });

  testWidgets('catalogue vide : le vide structurel, rien ne part', (
    tester,
  ) async {
    h.stubCatalog(const []);
    await h.pump(tester);

    expect(find.text('Aucun frais configuré pour cette année'), findsOneWidget);
    expect(find.text('Ouvrir la configuration'), findsOneWidget);
    expect(find.byType(RecoveryDashboardPerimeter), findsNothing);
    verifyNever(
      () => h.repository.dashboard(
        any(),
        any(),
        pendingWrites: any(named: 'pendingWrites'),
      ),
    );
  });

  group('échec au premier chargement', () {
    testWidgets('403 : erreur en place sous le périmètre, sans « Réessayer » '
        '(A16)', (tester) async {
      h.stubDashboard((_) => const Left(UnauthorizedFailure()));
      await h.pump(tester);

      expect(find.text('Accès refusé'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
      final perimeter = tester.getBottomLeft(
        find.byType(RecoveryDashboardPerimeter),
      );
      final error = tester.getTopLeft(find.byType(RecoveryResultsErrorState));
      expect(error.dy, greaterThanOrEqualTo(perimeter.dy));
    });

    testWidgets('réseau : « Réessayer » relit la question', (tester) async {
      h.stubDashboard((_) => const Left(NetworkFailure()));
      await h.pump(tester);

      expect(find.text('Connexion impossible'), findsOneWidget);
      expect(find.byType(RecoveryDashboardPerimeter), findsOneWidget);
      h.stubDashboard((_) => Right(recoveryDashboardFixture()));
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(h.askedQuestions(), hasLength(2));
      expect(find.text('Connexion impossible'), findsNothing);
    });
  });

  testWidgets('photo hors ligne : le bandeau daté et des exports inactifs', (
    tester,
  ) async {
    h.stubDashboard(
      (_) => Right(recoveryDashboardFixture().cached(DateTime.utc(2026, 9, 5))),
    );
    await h.pump(tester);

    expect(find.textContaining('Hors ligne · chiffres du '), findsOneWidget);
    final buttons = tester.widgetList<RecoveryFormatButtons>(
      find.byType(RecoveryFormatButtons),
    );
    expect(buttons, isNotEmpty);
    expect(buttons.every((b) => !b.enabled), isTrue);
  });

  testWidgets('R8 : « au moins » refusé en 400, la page retombe sur « a payé '
      'quelque chose » sans redemander une troisième fois', (tester) async {
    h.stubDashboard(
      (q) => q.rule == RecoveryRuleKind.atLeast
          ? const Left(
              ApiValidationFailure(
                code: ApiErrorCode.validation,
                detailCode: recoveryAtLeastUnavailable,
              ),
            )
          : Right(recoveryDashboardFixture()),
    );
    await h.pump(tester, query: 'frais=TUITION&regle=au-moins&montant=5000');

    final asked = h.askedQuestions();
    expect(asked.map((q) => q.rule), [
      RecoveryRuleKind.atLeast,
      RecoveryRuleKind.somePayment,
    ]);
    expect(h.address.containsKey('regle'), isFalse);
    expect(h.address['frais'], 'TUITION');
    expect(h.askedStudents().last.question.rule, RecoveryRuleKind.somePayment);
  });

  testWidgets('changer d\'onglet relit la liste (page 0), pas les chiffres ; '
      'le seuil de la simulation ne relit rien', (tester) async {
    await h.pump(tester);
    clearInteractions(h.repository);

    await tester.ensureVisible(find.text('Tous').first);
    await tester.tap(find.text('Tous').first);
    await tester.pumpAndSettle();

    final students = h.askedStudents();
    expect(students, hasLength(1));
    expect(students.single.tab, RecoveryTab.all);
    expect(students.single.page, 0);
    expect(h.address['onglet'], 'tous');
    verifyNever(
      () => h.repository.dashboard(
        any(),
        any(),
        pendingWrites: any(named: 'pendingWrites'),
      ),
    );

    tester.widget<Slider>(find.byType(Slider)).onChanged!(80);
    await tester.pumpAndSettle();

    expect(h.address['seuil'], '80');
    verifyNoMoreInteractions(h.repository);
  });

  for (final width in [360.0, 800.0, 1280.0]) {
    testWidgets('largeur $width au texte ×1,3 : rendu sans exception', (
      tester,
    ) async {
      await h.pump(tester, size: Size(width, 1600), textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(find.byType(RecoveryDashboardPerimeter), findsOneWidget);
    });
  }
}
