import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_contract_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_contract_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../staff_builders.dart';

class _MockSave extends Mock implements SaveStaffMemberUseCase {}

class _MockLoad extends Mock implements LoadStaffMemberUseCase {}

class _MockLoadContracts extends Mock implements LoadStaffContractsUseCase {}

class _MockAddContract extends Mock implements AddStaffContractUseCase {}

void main() {
  final getIt = GetIt.instance;
  late _MockSave save;
  late _MockLoad load;
  late _MockAddContract addContract;

  setUpAll(() {
    registerFallbackValue(const StaffMemberDraft(id: 'x'));
    registerFallbackValue(const StaffContractDraft());
  });

  setUp(() {
    save = _MockSave();
    load = _MockLoad();
    addContract = _MockAddContract();
    final loadContracts = _MockLoadContracts();
    when(() => loadContracts(any())).thenAnswer((_) async => const Right([]));
    getIt
      ..registerSingleton<SaveStaffMemberUseCase>(save)
      ..registerSingleton<LoadStaffMemberUseCase>(load)
      ..registerSingleton<IdGenerator>(const IdGenerator(Uuid()))
      ..registerFactory<StaffContractsCubit>(
        () => StaffContractsCubit(
          load: loadContracts,
          add: addContract,
          correct: CorrectStaffContractUseCase(_NoRepository()),
        ),
      );
  });
  tearDown(() async => getIt.reset());

  Future<void> pumpPage(
    WidgetTester tester, {
    StaffMember? member,
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StaffAgentPage(
          member: member,
          kind: member == null ? null : StaffContractKind.permanent,
          others: const [],
          today: '2026-09-29',
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('création : pas d erreur au premier regard, puis après Suivant', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Nouvel agent'), findsOneWidget);
    expect(find.text('NOUVEL AGENT · ÉTAPE 1 SUR 4'), findsOneWidget);
    expect(find.text('Champ requis'), findsNothing);

    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('5 champs à corriger'), findsOneWidget);
    expect(find.text('Champ requis'), findsWidgets);
    expect(tester.takeException(), isNull);
    verifyNever(() => save(any()));
  });

  testWidgets('consultation : lecture seule, et Modifier le profil', (
    tester,
  ) async {
    await pumpPage(tester, member: member('m-1', firstName: 'Jean'));

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
    await pumpPage(tester, member: member('m-1'));

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
    when(() => load(any())).thenAnswer((_) async => Right(agent));
    when(
      () => addContract(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    await pumpPage(tester, member: agent);

    await tester.tap(find.text('Poste & contrat'));
    await tester.pump();
    expect(find.text('Depuis le 01/09/2025'), findsOneWidget);
    expect(find.text('En vigueur'), findsOneWidget);

    await tester.tap(find.text('Nouveau contrat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poser le contrat'));
    await tester.pump();
    expect(find.text('Champ requis'), findsOneWidget);
    verifyNever(() => addContract(any(), any()));

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
        verify(() => addContract('m-1', captureAny())).captured.single
            as StaffContractDraft;
    expect(draft.kind, StaffContractKind.conventionne);
    expect(draft.secopeNumber, 'S-42');
    expect(draft.effectiveFrom, '2026-09-29');
    expect(find.text('Contrat enregistré sur la tablette.'), findsOneWidget);
    verify(() => load('m-1')).called(1);
    verifyNever(() => save(any()));
  });

  testWidgets('abandonner une modification demande confirmation', (
    tester,
  ) async {
    await pumpPage(tester, member: member('m-1', firstName: 'Jean'));
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
    await pumpPage(tester, size: const Size(640, 360));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _NoRepository extends Mock implements StaffContractRepository {}
