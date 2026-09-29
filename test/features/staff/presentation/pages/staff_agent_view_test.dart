import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_cubit.dart';
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

  testWidgets('une création enregistrée charge ses contrats et ses pièces', (
    tester,
  ) async {
    final draft = completeDraft();
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
    verifyNever(() => h.loadDossier(any()));

    await agent.save();
    await tester.pump();

    verify(() => h.loadDossier(draft.id)).called(1);
    verify(() => h.loadContracts(draft.id)).called(1);
  });
}
