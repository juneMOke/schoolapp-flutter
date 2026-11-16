import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_pending_probe.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_closing_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_screen.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements TreasuryDayRepository {}

class _MockProbe extends Mock implements CashPendingProbe {}

final _promoterClosure = CashClosure(
  id: 'clo-usd',
  registerId: 'reg-usd',
  currency: TreasuryCurrency.usd,
  cashDay: demoDay,
  closedAt: DateTime.utc(2026, 10, 22, 16, 45),
  closedByName: 'Junior Moke',
  closedByRole: 'DIRECTOR',
  matches: true,
  expectedInCents: 481900,
  declaredInCents: 481900,
  gapInCents: 0,
);

Future<void> _pump(
  WidgetTester tester,
  TreasuryDay day, {
  bool online = true,
  int pendingUsd = 0,
  bool canClose = true,
  bool canReopen = false,
  bool canAnswer = false,
  List<CashMovement> movements = const [],
}) async {
  final repo = _MockRepository();
  final probe = _MockProbe();
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
  ).thenAnswer((_) async => Right(treasuryWeek()));
  // La carte crée la liste dépliée par GetIt.
  final getIt = GetIt.instance;
  if (getIt.isRegistered<TreasuryDayRepository>()) {
    getIt.unregister<TreasuryDayRepository>();
  }
  getIt.registerSingleton<TreasuryDayRepository>(repo);
  when(() => probe.pendingFor(any())).thenAnswer(
    (invocation) async =>
        invocation.positionalArguments.first == TreasuryCurrency.usd
        ? pendingUsd
        : 0,
  );
  await tester.pumpWidget(
    treasuryHost(
      BlocProvider(
        create: (_) =>
            CashClosingCubit(repo, probe, initialDate: day.date)..load(),
        child: ClosingScreen(
          online: online,
          callbacks: ClosingCallbacks(
            close: canClose ? (_) {} : null,
            reopen: canReopen ? (_) {} : null,
            answer: canAnswer ? (_, _) async {} : null,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

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

  testAtReferenceFormats('une caisse ouverte, une clôturée avec écart', (
    tester,
    _,
  ) async {
    await _pump(
      tester,
      treasuryDay([usdDay(), cdfDay(closure: closedWithGap)]),
    );
    expect(find.text('Clôture de caisse'), findsOneWidget);
    expect(find.text('Jeudi 22 octobre 2026'), findsOneWidget);
  });

  testWidgets('le bandeau compte en vrai pluriel', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(
      tester,
      treasuryDay([usdDay(), cdfDay(closure: closedWithGap)]),
    );
    expect(find.textContaining('1 caisse sur 2 clôturée'), findsOneWidget);
  });

  testWidgets(
    'l écart reste lisible : montant, attendu, déclaré, justification',
    (tester) async {
      setTestWindow(tester, const Size(1280, 1400));
      await _pump(tester, treasuryDay([cdfDay(closure: closedWithGap)]));
      expect(
        find.textContaining('Écart de clôture -5 000 FC · manquant'),
        findsOneWidget,
      );
      expect(find.text('« Erreur de rendu de monnaie »'), findsOneWidget);
    },
  );

  testWidgets('hors ligne : le bouton est désactivé, et dit pourquoi', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay()]), online: false);
    expect(
      find.text('Clôture impossible hors ligne. Reconnectez la tablette.'),
      findsOneWidget,
    );
    expect(_closeButtonEnabled(tester), isFalse);
  });

  testWidgets('des envois en attente : le bouton attend (D2)', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay()]), pendingUsd: 2);
    expect(
      find.textContaining('2 mouvements pas encore envoyés au serveur'),
      findsOneWidget,
    );
    expect(_closeButtonEnabled(tester), isFalse);
  });

  testWidgets('une ligne arrivée après clôture attend sa réponse (R19)', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay(pendingAfterClosureCount: 1)]));
    expect(
      find.textContaining(
        '1 paiement arrivé après la clôture d\'hier à confirmer.',
      ),
      findsOneWidget,
    );
    expect(_closeButtonEnabled(tester), isFalse);
  });

  testWidgets('tout est prêt : le bouton s active', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay()]));
    expect(_closeButtonEnabled(tester), isTrue);
  });

  testWidgets('sans le droit de clôturer : consultation seule', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay()]), canClose: false);
    expect(find.textContaining('Consultation seule'), findsOneWidget);
    expect(find.text('Clôturer la caisse'), findsNothing);
  });

  testWidgets('clôturée par le promoteur : dit « (promoteur) » et offre la '
      'réouverture au promoteur', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(
      tester,
      treasuryDay([usdDay(closure: _promoterClosure)]),
      canReopen: true,
    );
    expect(find.textContaining('par Junior Moke (promoteur)'), findsOneWidget);
    expect(find.text('Rouvrir la journée'), findsOneWidget);
  });

  testWidgets('un jour passé non clôturé : « Non clôturée », pas de bouton', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    final past = DateTime(2026, 10, 21);
    await _pump(tester, treasuryDay([usdDay()], date: past));
    expect(find.text('Non clôturée'), findsOneWidget);
    expect(find.text('Clôturer la caisse'), findsNothing);
  });

  testWidgets('la réouverture n est pas offerte hors ligne', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    final closed = treasuryDay([usdDay(closure: _promoterClosure)]);
    await _pump(tester, closed, canReopen: true, online: false);
    expect(find.text('Rouvrir la journée'), findsNothing);
  });

  testWidgets('la réouverture n est pas offerte un jour passé', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    final past = DateTime(2026, 10, 21);
    await _pump(
      tester,
      treasuryDay([usdDay(closure: _promoterClosure)], date: past),
      canReopen: true,
    );
    expect(find.text('Rouvrir la journée'), findsNothing);
  });

  testWidgets(
    'une ligne arrivée après clôture se règle sur sa journée, même passée',
    (tester) async {
      setTestWindow(tester, const Size(1280, 1400));
      final past = DateTime(2026, 10, 21);
      await _pump(
        tester,
        treasuryDay([usdDay(pendingAfterClosureCount: 1)], date: past),
        canAnswer: true,
        movements: [afterClosurePayment],
      );
      await tester.tap(find.text('Voir le détail').first);
      await tester.pumpAndSettle();
      expect(find.text('Déjà en caisse hier'), findsOneWidget);
    },
  );

  testWidgets(
    'une ligne arrivée après clôture puis annulée garde sa question (PR back #230)',
    (tester) async {
      setTestWindow(tester, const Size(1280, 1400));
      final cancellation = CashMovement(
        id: 'mv-cancel',
        registerId: 'reg-usd',
        currency: TreasuryCurrency.usd,
        cashDay: demoDay,
        businessDay: demoDay,
        occurredAt: DateTime.utc(2026, 10, 22, 9),
        direction: MovementDirection.outflow,
        amountInCents: 2000,
        source: MovementSource.fees,
        nature: MovementNature.cancellation,
        label: 'Annulation — CF-RC-2627-000123',
        undoesMovementId: afterClosurePayment.id,
      );
      await _pump(
        tester,
        treasuryDay([usdDay()]),
        canAnswer: true,
        movements: [afterClosurePayment, cancellation],
      );
      await tester.tap(find.text('Voir le détail').first);
      await tester.pumpAndSettle();
      // Le libellé du serveur se range en colonnes : l'élève, puis les frais.
      expect(find.text('Kabongo Mwamba · 6e A'), findsOne);
      expect(find.text('Frais de scolarité'), findsOne);
      expect(find.text('Déjà en caisse hier'), findsOneWidget);
      // La liste des entrées ne montre pas la sortie qui l'a défaite.
      expect(find.text('Annulation — CF-RC-2627-000123'), findsNothing);
    },
  );

  testWidgets('sur une carte large, les trois cases tiennent sur une rangée', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay()]));
    final opening = tester.getTopLeft(find.text('OUVERTURE'));
    final outflows = tester.getTopLeft(find.text('SORTIES'));
    expect(outflows.dy, opening.dy);
  });

  testAtReferenceFormats('la semaine : totaux et jour par jour', (
    tester,
    _,
  ) async {
    await _pump(tester, treasuryDay([usdDay(), cdfDay()]));
    await tester.tap(find.textContaining(RegExp('^(Hebdomadaire|Semaine)\$')));
    await tester.pumpAndSettle();
    expect(find.text('Jour par jour'), findsOneWidget);
  });

  testWidgets('la semaine montre l écart en montant exact', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay(), cdfDay()]));
    await tester.tap(find.text('Hebdomadaire'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'écart ${TreasuryFormat.signedMoney(-500000, TreasuryCurrency.cdf)}',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Non clôturée'), findsOneWidget);
  });

  testWidgets('toucher une journée de la semaine la rouvre en Journalier', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    await _pump(tester, treasuryDay([usdDay(), cdfDay()]));
    await tester.tap(find.text('Hebdomadaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mer. 21 oct.'));
    await tester.pumpAndSettle();
    expect(find.text('Jour par jour'), findsNothing);
    expect(find.text('Mercredi 21 octobre 2026'), findsOneWidget);
  });

  testWidgets('le journalier reste verrouillé tant qu une caisse est ouverte', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1600));
    await _pump(
      tester,
      treasuryDay([usdDay(), cdfDay(closure: closedWithGap)]),
    );
    expect(
      find.text('Disponible après la clôture de la dernière caisse.'),
      findsOneWidget,
    );
    expect(find.text('PDF'), findsNothing);
  });

  testWidgets('journée clôturée : le rapport du jour s ouvre', (tester) async {
    setTestWindow(tester, const Size(1280, 1600));
    await _pump(tester, treasuryDay([cdfDay(closure: closedWithGap)]));
    expect(find.textContaining('RJ-20261022'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
  });

  testWidgets(
    'un jour passé non clôturé ne promet pas un rapport qui ne viendra pas',
    (tester) async {
      setTestWindow(tester, const Size(1280, 1600));
      final past = DateTime(2026, 10, 21);
      await _pump(tester, treasuryDay([usdDay()], date: past));
      expect(
        find.text('Disponible après la clôture de la dernière caisse.'),
        findsNothing,
      );
      expect(find.textContaining('Journée non clôturée'), findsOneWidget);
    },
  );
}

bool _closeButtonEnabled(WidgetTester tester) {
  final button = tester.widget<ButtonStyleButton>(
    find
        .ancestor(
          of: find.text('Clôturer la caisse'),
          matching: find.bySubtype<ButtonStyleButton>(),
        )
        .first,
  );
  return button.onPressed != null;
}
