import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/report_signatories_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/report_signatories_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/signatories_actions.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/signatories/report_signatories_section.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements ReportSignatoriesRepository {}

const _defaults = ReportSignatories(
  signatories: [],
  defaults: true,
  defaultSignatories: [
    ReportSignatory(
      rank: 1,
      caption: 'ÉTABLI PAR',
      function: 'Caissière',
      filledByCloser: true,
    ),
    ReportSignatory(
      rank: 2,
      caption: 'VÉRIFIÉ PAR',
      name: 'MWAMBA Paul',
      function: 'Préfet des études',
    ),
  ],
);

final _designated = ReportSignatories(
  signatories: const [
    ReportSignatory(
      rank: 1,
      caption: 'APPROUVÉ PAR',
      name: 'KASONGO Rose',
      function: 'Promotrice',
    ),
  ],
  defaults: false,
  updatedAtWire: '2026-11-15T16:00:00.123456Z',
  updatedAt: DateTime.utc(2026, 11, 15, 16),
  updatedByName: 'Jean MUKENDI',
);

/// Les boutons du bas de la modale défilent : on les amène à l'écran.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late _MockRepository repo;

  setUpAll(() => registerFallbackValue(<ReportSignatory>[]));

  setUp(() {
    repo = _MockRepository();
    when(() => repo.fetch()).thenAnswer((_) async => const Right(_defaults));
  });

  Future<ReportSignatoriesCubit> pump(
    WidgetTester tester, {
    bool canEdit = true,
  }) async {
    final cubit = ReportSignatoriesCubit(repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      treasuryHost(
        BlocProvider.value(
          value: cubit..load(),
          child: Builder(
            builder: (context) => ReportSignatoriesSection(
              onEdit: canEdit
                  ? () => editReportSignatories(context, cubit)
                  : null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testAtReferenceFormats('les blocs par défaut, imprimés dans l ordre', (
    tester,
    _,
  ) async {
    await pump(tester);
    expect(find.text('Signataires des rapports'), findsOneWidget);
    expect(find.text('Nom à écrire à la main'), findsOneWidget);
    expect(find.text('MWAMBA Paul'), findsOneWidget);
    expect(find.textContaining('Blocs par défaut'), findsOneWidget);
  });

  testWidgets('hors promoteur : consultation seule, aucun bouton', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 900));
    await pump(tester, canEdit: false);
    expect(find.text('Modifier les signataires'), findsNothing);
    expect(find.textContaining('Consultation seule'), findsOneWidget);
  });

  testAtReferenceFormats('la modale tient sur tous les formats', (
    tester,
    _,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    expect(find.text('Bloc 1'), findsOneWidget);
    expect(find.text('Bloc 2'), findsOneWidget);
  });

  testWidgets('enregistrer envoie l instant montré et la liste rognée', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    when(() => repo.fetch()).thenAnswer((_) async => Right(_designated));
    when(
      () => repo.replace(
        expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        signatories: any(named: 'signatories'),
      ),
    ).thenAnswer((_) async => Right(_designated));
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '  KASONGO Rosalie  ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final sent =
        verify(
              () => repo.replace(
                expectedUpdatedAt: '2026-11-15T16:00:00.123456Z',
                signatories: captureAny(named: 'signatories'),
              ),
            ).captured.single
            as List<ReportSignatory>;
    expect(sent.single.name, 'KASONGO Rosalie');
    expect(find.text('Signataires enregistrés.'), findsOneWidget);
  });

  testWidgets(
    'la liste a changé : la modale montre la nouvelle, sans rejouer',
    (tester) async {
      setTestWindow(tester, const Size(1280, 1400));
      when(
        () => repo.replace(
          expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
          signatories: any(named: 'signatories'),
        ),
      ).thenAnswer((_) async => Left(SignatoriesChangedFailure(_designated)));
      final cubit = await pump(tester);
      await tester.tap(find.text('Modifier les signataires'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'KABONGO Marie');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Jean MUKENDI vient de modifier'), findsOne);
      expect(find.text('Bloc 2'), findsNothing);
      expect(find.widgetWithText(TextField, 'KASONGO Rose'), findsOneWidget);
      verify(
        () => repo.replace(
          expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
          signatories: any(named: 'signatories'),
        ),
      ).called(1);
      expect(cubit.state.signatories, _designated);
      // L'essai suivant part de l'instant de la liste désormais montrée.
      when(
        () => repo.replace(
          expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
          signatories: any(named: 'signatories'),
        ),
      ).thenAnswer((_) async => Right(_designated));
      await tester.enterText(find.byType(TextField).at(1), 'KASONGO R.');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      verify(
        () => repo.replace(
          expectedUpdatedAt: '2026-11-15T16:00:00.123456Z',
          signatories: any(named: 'signatories'),
        ),
      ).called(1);
    },
  );

  testWidgets('quatre blocs au plus ; tout retirer revient aux défauts', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 2400));
    when(
      () => repo.replace(
        expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        signatories: any(named: 'signatories'),
      ),
    ).thenAnswer((_) async => const Right(_defaults));
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Ajouter un signataire'));
    await _tapVisible(tester, find.text('Ajouter un signataire'));
    expect(find.text('Bloc 4'), findsOneWidget);
    final full = find.text('4 signataires au plus');
    expect(full, findsOneWidget);
    final add = tester.widget<ButtonStyleButton>(
      find.ancestor(of: full, matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(add.onPressed, isNull);
    for (var i = 4; i >= 1; i--) {
      await _tapVisible(tester, find.byTooltip('Retirer le bloc $i'));
    }
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final sent =
        verify(
              () => repo.replace(
                expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
                signatories: captureAny(named: 'signatories'),
              ),
            ).captured.single
            as List<ReportSignatory>;
    expect(sent, isEmpty);
    expect(find.text('Blocs par défaut rétablis.'), findsOneWidget);
  });

  testWidgets('« la personne qui a clôturé » suit le premier rang', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsOneWidget);
    await tester.tap(find.byTooltip('Descendre le bloc 1'));
    await tester.pumpAndSettle();
    // Le bloc qui monte au premier rang n'hérite pas de la case cochée.
    final tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(tile.value, isFalse);
  });

  testWidgets('un échec de lecture : l état d erreur et « Réessayer »', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 900));
    when(
      () => repo.fetch(),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    await pump(tester);
    expect(find.text('Modifier les signataires'), findsNothing);
    when(() => repo.fetch()).thenAnswer((_) async => const Right(_defaults));
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('MWAMBA Paul'), findsOneWidget);
  });

  testWidgets('rien de changé : rien à enregistrer ; les défauts préviennent', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ne suivront plus les titulaires'), findsOne);
    final save = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Enregistrer'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('une saisie incomplète dit ce qui manque, sans rien envoyer', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 2000));
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Ajouter un signataire'));
    await _tapVisible(tester, find.text('Enregistrer'));
    expect(find.text('Légende obligatoire, 40 caractères au plus.'), findsOne);
    expect(find.text('Fonction obligatoire, 60 caractères au plus.'), findsOne);
    verifyNever(
      () => repo.replace(
        expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        signatories: any(named: 'signatories'),
      ),
    );
  });

  testWidgets('revenir aux défauts demande confirmation, puis vide la liste', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1400));
    when(() => repo.fetch()).thenAnswer((_) async => Right(_designated));
    when(
      () => repo.replace(
        expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        signatories: any(named: 'signatories'),
      ),
    ).thenAnswer((_) async => const Right(_defaults));
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revenir aux blocs par défaut'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La liste désignée sera effacée'), findsOne);
    await tester.tap(find.text('Revenir aux blocs par défaut').last);
    await tester.pumpAndSettle();
    final sent =
        verify(
              () => repo.replace(
                expectedUpdatedAt: '2026-11-15T16:00:00.123456Z',
                signatories: captureAny(named: 'signatories'),
              ),
            ).captured.single
            as List<ReportSignatory>;
    expect(sent, isEmpty);
    expect(find.text('Blocs par défaut rétablis.'), findsOneWidget);
  });

  testWidgets('pendant l envoi, Échap ne ferme pas la modale', (tester) async {
    setTestWindow(tester, const Size(1280, 1400));
    final answer = Completer<Either<Failure, ReportSignatories>>();
    when(
      () => repo.replace(
        expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        signatories: any(named: 'signatories'),
      ),
    ).thenAnswer((_) => answer.future);
    await pump(tester);
    await tester.tap(find.text('Modifier les signataires'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'KABONGO Marie');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Bloc 1'), findsOneWidget);
    answer.complete(const Right(_defaults));
    await tester.pumpAndSettle();
    expect(find.text('Bloc 1'), findsNothing);
  });

  test('un refus « liste changée » illisible relit la liste', () async {
    when(
      () => repo.replace(
        expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
        signatories: any(named: 'signatories'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        TreasuryRefusalFailure(TreasuryRefusal.signatoriesChanged),
      ),
    );
    final cubit = ReportSignatoriesCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    when(() => repo.fetch()).thenAnswer((_) async => Right(_designated));
    await cubit.save(const []);
    expect(cubit.state.signatories, _designated);
  });
}
