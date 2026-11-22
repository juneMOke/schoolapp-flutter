import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_search.dart';

import '../../../../fixtures/recovery_fixtures.dart';
import 'students_test_harness.dart';

String fmt(int cents, String c) => MoneyFormat.format(Money(cents, c));

void main() {
  group('Règle (R8, A8)', () {
    testWidgets('chaque choix annonce son effet avant d’être touché', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(find.text('Est en ordre l\'élève qui…'), findsOneWidget);
      expect(find.text('a payé quelque chose'), findsOneWidget);
      expect(find.text('a tout soldé'), findsOneWidget);
      expect(find.text('a payé au moins'), findsOneWidget);
      expect(find.text('163 en ordre'), findsOneWidget);
      expect(find.text('104 en ordre'), findsOneWidget);
      expect(find.text('saisissez un montant'), findsOneWidget);
      expect(
        find.text("Donc pas en ordre : n'a rien versé du tout."),
        findsOneWidget,
      );
    });

    testWidgets(
      'toucher un choix le remonte ; les flèches passent au suivant',
      (tester) async {
        final calls = await pumpPanel(tester);
        await tester.tap(find.text('a tout soldé'));
        await tester.pump();
        expect(calls.rules, [RecoveryRuleKind.fullySettled]);
        // Focus sur le premier choix, puis flèche droite.
        await tester.tap(find.text('a payé quelque chose'));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(calls.rules.last, RecoveryRuleKind.fullySettled);
      },
    );

    testWidgets('le montant : chiffres seuls, en centimes, vide ⇒ null', (
      tester,
    ) async {
      final calls = await pumpPanel(tester);
      final field = find.byType(TextField).first;
      await tester.enterText(field, '15a0');
      await tester.pump();
      expect(calls.thresholds.last, 15000);
      // Saisir dans le champ choisit « au moins ».
      expect(calls.rules, contains(RecoveryRuleKind.atLeast));
      await tester.enterText(field, '');
      await tester.pump();
      expect(calls.thresholds.last, isNull);
    });

    testWidgets('« au moins 150 USD » : compteur, contraire et verbes (A9)', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        rule: RecoveryRuleKind.atLeast,
        threshold: 15000,
        tab: RecoveryTab.inOrder,
      );
      final m = fmt(15000, 'USD');
      expect(
        find.text(
          'Donc pas en ordre : a versé moins que le montant saisi ($m).',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Ces élèves ont payé au moins $m',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '150',
      );
    });

    testWidgets('le champ se resynchronise quand le parent oublie le montant', (
      tester,
    ) async {
      final calls = PanelCalls();
      await pumpPanel(
        tester,
        rule: RecoveryRuleKind.atLeast,
        threshold: 15000,
        calls: calls,
      );
      await pumpPanel(tester, rule: RecoveryRuleKind.atLeast, calls: calls);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '',
      );
    });

    testWidgets(
      'mixte : « au moins » grisé, ligne ambre, deux lignes de montant (A3)',
      (tester) async {
        final page = pageWith(
          recoveryStudentsFixture(),
          currencies: ['CDF', 'USD'],
          content: [mixedRow()],
          totalElements: 1,
          totalPages: 1,
        );
        final calls = await pumpPanel(
          tester,
          dashboard: recoveryMixedDashboardFixture(),
          students: loaded(page),
          tab: RecoveryTab.all,
        );
        expect(
          find.text('Indisponible : francs et dollars cochés ensemble'),
          findsOneWidget,
        );
        expect(
          find.textContaining('chaque devise se lit à part'),
          findsOneWidget,
        );
        await tester.tap(find.text('a payé au moins'));
        await tester.pump();
        expect(calls.rules, isEmpty);
        // Payé : dollars puis francs, jamais additionnés.
        expect(find.text(fmt(0, 'USD')), findsOneWidget);
        expect(find.text(fmt(2500000, 'CDF')), findsWidgets);
      },
    );
  });

  group('Onglets et liste (R9, R10, A6, A7, A18)', () {
    testWidgets('compteurs, sous-lignes et titre composé par le serveur', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(find.text('315'), findsOneWidget);
      expect(find.text('163'), findsOneWidget);
      expect(find.text('478'), findsOneWidget);
      expect(find.text('reste dû ${fmt(5640000, 'USD')}'), findsOneWidget);
      expect(find.text("34 % de l'effectif"), findsOneWidget);
      expect(
        find.textContaining(
          "Liste des élèves qui n'ont rien payé (pas en ordre)",
          findRichText: true,
        ),
        findsOneWidget,
      );
      // Chaque ligne rouge porte aussi le mot (A18).
      expect(find.text('À relancer'), findsNWidgets(1 + 10));
      expect(find.text('Rien payé'), findsNWidgets(10));
      expect(find.text('1–10 sur 315 élèves'), findsOneWidget);
      expect(find.text('Page 1 / 32'), findsOneWidget);
      expect(
        find.textContaining('Exporter ces 315 élèves', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('onglet, ligne, page et pastille remontent', (tester) async {
      final calls = await pumpPanel(tester);
      await tester.tap(find.text('Tous'));
      await tester.tap(find.text('KABONGO Mukendi Jean'));
      await tester.tap(find.byTooltip('Page suivante').first);
      await tester.tap(find.text('Sur Scolarité'));
      await tester.pump();
      expect(calls.tabs, [RecoveryTab.all]);
      expect(calls.students.single.studentId, 's0');
      expect(calls.pages, [1]);
      expect(calls.fees, 1);
    });

    testWidgets('Entrée sur une ligne ouvre la fiche (I11)', (tester) async {
      final calls = await pumpPanel(tester);
      Focus.of(
        tester.element(find.text('KABONGO Mukendi Jean')),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls.students, isNotEmpty);
    });

    testWidgets('la recherche attend une pause de frappe', (tester) async {
      final calls = await pumpPanel(tester);
      await tester.enterText(find.byType(TextField).last, 'kab');
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls.searches, isEmpty);
      await tester.pump(RecoveryStudentsSearch.debounce);
      expect(calls.searches, ['kab']);
    });
  });

  group('États (§5)', () {
    RecoveryStudentsPage empty(RecoveryTabCounts counts) => pageWith(
      recoveryStudentsFixture(),
      content: const [],
      counts: counts,
      totalElements: 0,
      totalPages: 0,
    );

    testWidgets('onglets vides et recherche vide ; exports inactifs', (
      tester,
    ) async {
      const none = RecoveryTabCounts(toChase: 0, inOrder: 0, all: 478);
      await pumpPanel(tester, students: loaded(empty(none)));
      expect(
        find.text('Tous les élèves sont en ordre selon cette règle.'),
        findsOneWidget,
      );
      final pdf = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'PDF').first,
      );
      expect(pdf.onPressed, isNull);

      await pumpPanel(
        tester,
        students: loaded(empty(none)),
        tab: RecoveryTab.inOrder,
      );
      expect(
        find.text('Aucun élève en ordre selon cette règle.'),
        findsOneWidget,
      );

      await pumpPanel(tester, students: loaded(empty(none)), search: 'zz');
      expect(find.text('Aucun élève ne correspond à « zz ».'), findsOneWidget);
    });

    testWidgets('hors ligne : liste lisible, exports inactifs avec la raison', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        exportsEnabled: false,
        exportsDisabledReason: 'Les exports attendent le réseau.',
      );
      expect(find.text('KABONGO Mukendi Jean'), findsOneWidget);
      expect(find.byTooltip('Les exports attendent le réseau.'), findsWidgets);
    });

    testWidgets('fantômes avant la première page ; liste gardée en relecture', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        students: const RecoveryStudentsState(
          query: tQuery,
          status: RecoveryLoadStatus.loading,
        ),
      );
      expect(find.text('KABONGO Mukendi Jean'), findsNothing);
      expect(find.text('163 en ordre'), findsOneWidget);

      await pumpPanel(
        tester,
        students: RecoveryStudentsState(
          query: tQuery,
          status: RecoveryLoadStatus.loading,
          page: recoveryStudentsFixture(),
        ),
      );
      expect(find.text('KABONGO Mukendi Jean'), findsOneWidget);
    });

    testWidgets('403 : le droit manque, sans « Réessayer » ; chiffres gardés', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        students: const RecoveryStudentsState(
          query: tQuery,
          status: RecoveryLoadStatus.failure,
          failure: UnauthorizedFailure(),
        ),
      );
      expect(find.textContaining('pas la liste nominative'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
      expect(find.text('163 en ordre'), findsOneWidget);
    });

    testWidgets('réseau : « Réessayer » relance', (tester) async {
      final calls = await pumpPanel(
        tester,
        students: const RecoveryStudentsState(
          query: tQuery,
          status: RecoveryLoadStatus.failure,
          failure: NetworkFailure(),
        ),
      );
      await tester.tap(find.text('Réessayer'));
      expect(calls.retries, 1);
    });
  });

  group('Formats (§4.1, §4.5)', () {
    for (final width in [360.0, 600.0, 700.0, 800.0, 1280.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('$width dp, texte ×$scale : aucun débordement', (
          tester,
        ) async {
          await pumpPanel(tester, width: width, textScale: scale);
          expect(tester.takeException(), isNull);
          await pumpPanel(
            tester,
            width: width,
            textScale: scale,
            dashboard: recoveryMixedDashboardFixture(),
            students: loaded(
              pageWith(
                recoveryStudentsFixture(),
                currencies: ['CDF', 'USD'],
                content: [mixedRow(), ...recoveryStudentsFixture().content],
              ),
            ),
            tab: RecoveryTab.all,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('sous 600 : cartes sans en-tête ; 600-760 : repliée', (
      tester,
    ) async {
      await pumpPanel(tester, width: 360);
      expect(find.text('Élève'), findsNothing);
      expect(find.text('Élève · classe'), findsNothing);
      await pumpPanel(tester, width: 700);
      expect(find.text('Élève · classe'), findsOneWidget);
      await pumpPanel(tester, width: 1280);
      expect(find.text('Élève'), findsOneWidget);
      expect(find.text('Classe'), findsOneWidget);
    });
  });
}
