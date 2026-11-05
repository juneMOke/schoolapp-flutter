import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_dossier_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff_builders.dart';
import 'staff_agent_harness.dart';

void main() {
  final getIt = GetIt.instance;
  late StaffAgentHarness h;

  setUpAll(StaffAgentHarness.registerFallbacks);
  setUp(() => (h = StaffAgentHarness()).register(getIt));
  tearDown(() async => getIt.reset());

  /// La vue d'une création, sur [agent] et les cubits de la page.
  Future<void> pumpCreation(WidgetTester tester, StaffAgentCubit agent) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: agent),
            BlocProvider(create: (_) => getIt<StaffContractsCubit>()),
            BlocProvider(create: (_) => getIt<StaffDossierCubit>()),
          ],
          child: const StaffAgentView(kind: null, today: '2026-09-29'),
        ),
      ),
    );
  }

  StaffAgentCubit creating(StaffMemberDraft draft) {
    when(() => h.save(any())).thenAnswer((_) async => const Right(unit));
    when(
      () => h.load(draft.id),
    ).thenAnswer((_) async => Right(member(draft.id)));
    final agent = StaffAgentCubit(
      save: h.save,
      load: h.load,
      others: const [],
      today: '2026-09-29',
      draft: draft,
    );
    addTearDown(agent.close);
    return agent;
  }

  testWidgets('une création enregistrée charge ses contrats et ses pièces', (
    tester,
  ) async {
    final draft = completeDraft();
    final agent = creating(draft);
    await pumpCreation(tester, agent);
    verifyNever(() => h.loadDossier(any()));

    await agent.save();
    await tester.pump();

    verify(() => h.loadDossier(draft.id)).called(1);
    verify(() => h.loadContracts(draft.id)).called(1);
    // Sans contrat saisi, rien ne se pose : un agent sans contrat est permis.
    verifyNever(() => h.addContract(any(), any()));
  });

  testWidgets('le contrat initial se pose à la suite de la fiche, et la '
      'fiche s ouvre sur « Poste & contrat »', (tester) async {
    const contract = StaffContractDraft(
      kind: StaffContractKind.permanent,
      effectiveFrom: '2026-09-01',
      amount: '250',
    );
    when(
      () => h.addContract(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    final draft = completeDraft();
    final agent = creating(draft)..updateInitialContract((_) => contract);
    await pumpCreation(tester, agent);

    await agent.save();
    await tester.pump();
    await tester.pump();

    verify(() => h.addContract(draft.id, contract)).called(1);
    expect(agent.state.step, StaffAgentState.jobStep);
    expect(find.text('Contrat enregistré sur la tablette.'), findsOneWidget);
  });

  group('création entamée', () {
    /// La vue poussée au-dessus d'une page « Fichier », comme depuis le
    /// fichier du personnel.
    Future<void> pumpPushed(WidgetTester tester, StaffAgentCubit agent) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: agent),
                        BlocProvider(
                          create: (_) => getIt<StaffContractsCubit>(),
                        ),
                        BlocProvider(create: (_) => getIt<StaffDossierCubit>()),
                      ],
                      child: const StaffAgentView(
                        kind: null,
                        today: '2026-09-29',
                      ),
                    ),
                  ),
                ),
                child: const Text('Fichier'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Fichier'));
      await tester.pumpAndSettle();
    }

    testWidgets('une fiche à peine ouverte se quitte sans question', (
      tester,
    ) async {
      final agent = creating(const StaffMemberDraft(id: 'new'));
      await pumpPushed(tester, agent);

      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();

      expect(find.text('Abandonner les modifications ?'), findsNothing);
      expect(find.text('Fichier'), findsOneWidget);
    });

    testWidgets('une écriture en vol retient la page : le contrat initial '
        'se pose à sa suite', (tester) async {
      const contract = StaffContractDraft(
        kind: StaffContractKind.permanent,
        effectiveFrom: '2026-09-01',
        amount: '250',
      );
      when(
        () => h.addContract(any(), any()),
      ).thenAnswer((_) async => const Right(unit));
      final draft = completeDraft();
      final agent = creating(draft)..updateInitialContract((_) => contract);
      // Né dans le test, sous FakeAsync : il s'achève quand on le décide.
      final written = Completer<Either<Failure, Unit>>();
      when(() => h.save(any())).thenAnswer((_) => written.future);
      await pumpPushed(tester, agent);

      unawaited(agent.save());
      await tester.pump();
      expect(agent.state.saving, isTrue);

      await tester.tap(find.byTooltip('Retour'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(StaffAgentView), findsOneWidget);

      written.complete(const Right(unit));
      await tester.pumpAndSettle();
      verify(() => h.addContract(draft.id, contract)).called(1);
    });

    testWidgets('une saisie commencée demande avant de partir, et '
        '« Continuer la saisie » la garde', (tester) async {
      final agent = creating(const StaffMemberDraft(id: 'new'));
      await pumpPushed(tester, agent);
      agent.updateDraft((d) => d.copyWith(firstName: 'Paul'));
      await tester.pump();

      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.text('Abandonner les modifications ?'), findsOneWidget);

      await tester.tap(find.text('Continuer la saisie'));
      await tester.pumpAndSettle();
      expect(find.byType(StaffAgentView), findsOneWidget);
      expect(agent.state.draft.firstName, 'Paul');

      // Précédent du système : la même question, la page ne part pas seule.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Abandonner les modifications ?'), findsOneWidget);

      await tester.tap(find.text('Abandonner'));
      await tester.pumpAndSettle();
      expect(find.byType(StaffAgentView), findsNothing);
      expect(find.text('Fichier'), findsOneWidget);
    });
  });
}
