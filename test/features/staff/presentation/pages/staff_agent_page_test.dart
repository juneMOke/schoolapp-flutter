import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../../staff_builders.dart';
import 'staff_agent_harness.dart';

void main() {
  final getIt = GetIt.instance;
  late StaffAgentHarness h;

  setUpAll(StaffAgentHarness.registerFallbacks);
  setUp(() => (h = StaffAgentHarness()).register(getIt));
  tearDown(() async => getIt.reset());

  testWidgets('création : pas d erreur au premier regard, puis après Suivant', (
    tester,
  ) async {
    await h.pump(tester);

    expect(find.text('Nouvel agent'), findsOneWidget);
    expect(find.text('NOUVEL AGENT · ÉTAPE 1 SUR 4'), findsOneWidget);
    expect(find.text('Champ requis'), findsNothing);

    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('5 champs à corriger'), findsOneWidget);
    expect(find.text('Champ requis'), findsWidgets);
    expect(tester.takeException(), isNull);
    verifyNever(() => h.save(any()));
  });

  testWidgets('consultation : lecture seule, et Modifier le profil', (
    tester,
  ) async {
    await h.pump(tester, member: member('m-1', firstName: 'Jean'));

    expect(find.text('Jean Kalala'), findsOneWidget);
    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Suivant'), findsNothing);
    expect(find.text('CF-AG-0001'), findsOneWidget);

    await tester.tap(find.text('Modifier le profil'));
    await tester.pump();

    expect(find.text('MODIFICATION DU PROFIL'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en modification, les étapes sont libres', (tester) async {
    await h.pump(tester, member: member('m-1'));

    await tester.tap(find.text('Poste & contrat'));
    await tester.pump();

    expect(find.text('Poste'), findsOneWidget);
    expect(find.text('Enseignant titulaire'), findsWidgets);
  });

  testWidgets('les contrats se posent à part, sans modifier la fiche', (
    tester,
  ) async {
    final agent = member(
      'm-1',
      contracts: [period(StaffContractKind.permanent, from: '2025-09-01')],
    );
    when(() => h.load(any())).thenAnswer((_) async => Right(agent));
    when(
      () => h.addContract(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    await h.pump(tester, member: agent);

    await tester.tap(find.text('Poste & contrat'));
    await tester.pump();
    expect(find.text('Depuis le 01/09/2025'), findsOneWidget);
    expect(find.text('En vigueur'), findsOneWidget);

    await tester.tap(find.text('Nouveau contrat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poser le contrat'));
    await tester.pump();
    expect(find.text('Champ requis'), findsOneWidget);
    verifyNever(() => h.addContract(any(), any()));

    await tester.tap(find.text('Conventionné'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.ancestor(
          of: find.textContaining('Matricule SECOPE'),
          matching: find.byType(EteeloTextInput),
        ),
        matching: find.byType(EditableText),
      ),
      'S-42',
    );
    await tester.tap(find.text('Poser le contrat'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => h.addContract('m-1', captureAny())).captured.single
            as StaffContractDraft;
    expect(draft.kind, StaffContractKind.conventionne);
    expect(draft.secopeNumber, 'S-42');
    expect(draft.effectiveFrom, '2026-09-29');
    expect(find.text('Contrat enregistré sur la tablette.'), findsOneWidget);
    verify(() => h.load('m-1')).called(1);
    verifyNever(() => h.save(any()));
  });

  testWidgets('les pièces exigées par le contrat, versées ou à verser', (
    tester,
  ) async {
    final agent = member(
      'm-1',
      contracts: [period(StaffContractKind.permanent, from: '2025-09-01')],
    );
    final identity = document('m-1', 'ID');
    when(() => h.loadDossier('m-1')).thenAnswer(
      (_) async => Right(
        StaffDossierSnapshot(types: documentTypes, documents: [identity]),
      ),
    );
    when(
      () => h.openDocument(identity),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    await h.pump(tester, member: agent);

    await tester.tap(find.text('Diplômes & pièces'));
    // Le cubit du dossier naît à la première lecture de l'étape : sa relecture
    // se dénoue, puis se peint, aux tours suivants.
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Pièces du dossier'), findsOneWidget);
    expect(find.text('1/3 pièces'), findsOneWidget);
    expect(find.text('Lettre de désignation'), findsOneWidget);
    expect(find.text('Contrat de prestation'), findsNothing);
    expect(find.text('À verser'), findsNWidgets(2));
    expect(find.text('Remplacer'), findsOneWidget);

    await tester.ensureVisible(find.text('Voir'));
    await tester.tap(find.text('Voir'));
    await tester.pump();
    expect(find.textContaining('Hors ligne'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abandonner une modification demande confirmation', (
    tester,
  ) async {
    await h.pump(tester, member: member('m-1', firstName: 'Jean'));
    await tester.tap(find.text('Modifier le profil'));
    await tester.pump();

    await tester.enterText(find.byType(EditableText).at(2), 'Paul');
    await tester.pump();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Abandonner les modifications ?'), findsOneWidget);
    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Jean Kalala'), findsOneWidget);
  });

  testWidgets('téléphone en paysage : rien ne déborde', (tester) async {
    await h.pump(tester, size: const Size(640, 360));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
