import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table_cards.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_pending_probe.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_day_pane.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_screen.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/period/period_view.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements TreasuryDayRepository {}

class _MockProbe extends Mock implements CashPendingProbe {}

/// Les largeurs de CONTENU que reçoit l'écran (fenêtre − menu − marges de
/// page) : l'hôte de test n'a ni coquille ni marge, la fenêtre de test est
/// donc la largeur reçue. Audit adaptatif Trésorerie, matrice des largeurs.
const _laptop1366 = 1038.0; // 1 366 − 280 − 48
const _laptop1440 = 1112.0; // 1 440 − 280 − 48
const _tablet10Landscape = 1148.0; // 1 280 − 84 − 48
const _threshold = 1140.0; // AppBreakpoints.treasuryPeriodSideBySideMin
const _laptop1536 = 1208.0; // 1 536 − 280 − 48
const _desk1920 = 1592.0; // 1 920 − 280 − 48

/// Un mois de journées ouvrées (octobre 2026, dimanches exclus), la plus
/// récente en tête : assez pour que la page défile.
TreasuryPeriod _month({int cdfInflowsInCents = 22640000}) {
  final week = treasuryWeek();
  final days = <PeriodDayRow>[
    for (var d = 31; d >= 1; d--)
      if (DateTime(2026, 10, d).weekday != DateTime.sunday)
        PeriodDayRow(
          day: DateTime(2026, 10, d),
          cells: [
            const PeriodDayCell(
              registerId: 'reg-usd',
              inflowsInCents: 18100,
              outflowsInCents: 29500,
              gapInCents: 0,
              closingBalanceInCents: 481900,
              status: ClosureStatus.closed,
            ),
            PeriodDayCell(
              registerId: 'reg-cdf',
              inflowsInCents: cdfInflowsInCents,
              outflowsInCents: 34510000,
              gapInCents: 0,
              closingBalanceInCents: 332626900,
              status: ClosureStatus.closed,
            ),
          ],
        ),
  ];
  return TreasuryPeriod(
    from: DateTime(2026, 10, 19),
    to: DateTime(2026, 10, 24),
    registers: week.registers,
    days: days,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  TreasuryPeriod? period,
  List<CashMovement> movements = const [],
}) async {
  final repo = _MockRepository();
  final probe = _MockProbe();
  final day = treasuryDay([usdDay(), cdfDay()]);
  when(() => repo.day(any())).thenAnswer((_) async => Right(day));
  when(
    () => repo.movements(
      any(),
      registerId: any(named: 'registerId'),
      direction: any(named: 'direction'),
    ),
  ).thenAnswer((_) async => Right(movements));
  when(
    () => repo.period(any(), any()),
  ).thenAnswer((_) async => Right(period ?? treasuryWeek()));
  final getIt = GetIt.instance;
  if (getIt.isRegistered<TreasuryDayRepository>()) {
    getIt.unregister<TreasuryDayRepository>();
  }
  getIt.registerSingleton<TreasuryDayRepository>(repo);
  when(() => probe.pendingFor(any())).thenAnswer((_) async => 0);
  await tester.pumpWidget(
    treasuryHost(
      BlocProvider(
        create: (_) => CashClosingCubit(repo, probe, initialDate: day.date),
        child: ClosingScreen(
          online: true,
          callbacks: ClosingCallbacks(close: (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openWeek(WidgetTester tester) async {
  // « Semaine » sur un écran étroit (libellés courts).
  await tester.tap(find.textContaining(RegExp(r'^(Hebdomadaire|Semaine)$')));
  await tester.pumpAndSettle();
}

/// Le tableau « Jour par jour » défile-t-il de côté ?
Finder _sideScroll() => find.descendant(
  of: find.byType(EteeloColumnTable),
  matching: find.byWidgetPredicate(
    (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
  ),
);

/// La journée à côté de la période : un `ClosingDayPane` à côté d'une
/// `PeriodView`.
bool _sideBySide(WidgetTester tester) =>
    find.byType(PeriodView).evaluate().isNotEmpty &&
    find.byType(ClosingDayPane).evaluate().isNotEmpty;

void main() {
  setUpAll(() {
    registerFallbackValue(TreasuryCurrency.usd);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(MovementDirection.inflow);
  });
  tearDown(() {
    if (GetIt.instance.isRegistered<TreasuryDayRepository>()) {
      GetIt.instance.unregister<TreasuryDayRepository>();
    }
  });

  group('Clôture S/M : le tableau « Jour par jour » reste entier', () {
    for (final width in [
      _threshold,
      _tablet10Landscape,
      _laptop1536,
      _desk1920,
    ]) {
      testWidgets('à ${width.toInt()} de contenu : la journée à côté, le '
          'tableau sans défilement de côté', (tester) async {
        setTestWindow(tester, Size(width, 1400));
        await _pump(tester);
        await _openWeek(tester);
        await tester.tap(find.text('Mer. 21 oct.'));
        await tester.pumpAndSettle();
        expect(_sideBySide(tester), isTrue);
        expect(_sideScroll(), findsNothing);
        expect(find.byType(EteeloColumnTableCards), findsNothing);
        expect(find.byType(EteeloColumnTable), findsOneWidget);
      });
    }

    for (final width in [_laptop1366, _laptop1440]) {
      testWidgets('à ${width.toInt()} de contenu (portable) : la période en '
          'tableau entier, la journée la remplace', (tester) async {
        setTestWindow(tester, Size(width, 1400));
        await _pump(tester);
        await _openWeek(tester);
        expect(find.byType(ClosingDayPane), findsNothing);
        expect(_sideScroll(), findsNothing);
        expect(find.byType(EteeloColumnTableCards), findsNothing);

        await tester.tap(find.text('Mer. 21 oct.'));
        await tester.pumpAndSettle();
        expect(find.byType(PeriodView), findsNothing);
        expect(find.text('Mercredi 21 octobre 2026'), findsOneWidget);
      });
    }
  });

  testWidgets('une journée choisie en bas du mois ramène son volet à '
      'l écran', (tester) async {
    setTestWindow(tester, const Size(_desk1920, 800));
    await _pump(tester, period: _month());
    await _openWeek(tester);
    final last = find.byType(EteeloColumnTableRow).last;
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    // Le contraste : le volet est passé au-dessus de l'écran.
    expect(tester.getTopLeft(find.byType(ClosingDayPane)).dy, lessThan(0));

    await tester.tap(last);
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.byType(ClosingDayPane)).dy;
    expect(top, greaterThanOrEqualTo(0));
    expect(top, lessThan(800));
  });

  testWidgets('retoucher la journée déjà ouverte ramène aussi son volet', (
    tester,
  ) async {
    setTestWindow(tester, const Size(_desk1920, 800));
    await _pump(tester, period: _month());
    await _openWeek(tester);
    final last = find.byType(EteeloColumnTableRow).last;
    await tester.ensureVisible(last);
    await tester.tap(last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(ClosingDayPane)).dy, lessThan(0));

    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(ClosingDayPane)).dy,
      greaterThanOrEqualTo(0),
    );
  });

  testWidgets('volet déjà visible : choisir une journée ne fait pas défiler', (
    tester,
  ) async {
    setTestWindow(tester, const Size(_desk1920, 1400));
    await _pump(tester);
    await _openWeek(tester);
    final before = tester.getTopLeft(find.byType(PeriodView)).dy;
    await tester.tap(find.text('Mer. 21 oct.'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(PeriodView)).dy, before);
  });

  testWidgets('un montant CDF à 8 chiffres reste entier à côté du volet, '
      'texte ×1,3', (tester) async {
    setTestWindow(tester, const Size(_threshold, 1400));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, period: _month(cdfInflowsInCents: 1250000000));
    await _openWeek(tester);
    await tester.tap(find.byType(EteeloColumnTableRow).first);
    await tester.pumpAndSettle();
    expect(_sideBySide(tester), isTrue);
    final amount = TreasuryFormat.signedMoney(1250000000, TreasuryCurrency.cdf);
    final texts = find.text(amount);
    expect(texts, findsWidgets);
    for (final element in texts.evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      // Posé à sa largeur naturelle : sur une seule ligne, jamais coupé.
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(
          paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
        ),
        reason: 'le montant $amount est coupé',
      );
    }
  });

  testAtReferenceFormats('la semaine puis une journée, sans débordement', (
    tester,
    _,
  ) async {
    await _pump(tester, period: _month());
    await _openWeek(tester);
    // Une ligne de tableau ou une carte, selon la largeur : son libellé.
    final day = find.text('Sam. 31 oct.');
    await tester.ensureVisible(day);
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(find.byType(ClosingDayPane), findsOneWidget);
  });

  group('Journalier : le registre déplié garde ses colonnes', () {
    testWidgets('portable de 1 366 : les cartes l une sous l autre, le N° '
        'de reçu en colonne', (tester) async {
      setTestWindow(tester, const Size(_laptop1366, 1600));
      await _pump(tester, movements: [afterClosurePayment]);
      final cards = find.byType(DayCard);
      expect(cards, findsNWidgets(2));
      expect(
        tester.getTopLeft(cards.at(1)).dy,
        greaterThan(tester.getTopLeft(cards.at(0)).dy),
      );
      await tester.tap(find.text('Voir le détail').first);
      await tester.pumpAndSettle();
      expect(find.text('N° REÇU'), findsOneWidget);
    });

    testWidgets('poste de 1 536 : les deux cartes côte à côte', (tester) async {
      setTestWindow(tester, const Size(_laptop1536, 1600));
      await _pump(tester, movements: [afterClosurePayment]);
      final cards = find.byType(DayCard);
      expect(
        tester.getTopLeft(cards.at(1)).dy,
        tester.getTopLeft(cards.at(0)).dy,
      );
      await tester.tap(find.text('Voir le détail').first);
      await tester.pumpAndSettle();
      expect(find.text('N° REÇU'), findsOneWidget);
    });
  });
}
