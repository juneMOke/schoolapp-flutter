import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_contract_use_cases.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_document_use_cases.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_dossier_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

class MockSaveMember extends Mock implements SaveStaffMemberUseCase {}

class MockLoadMember extends Mock implements LoadStaffMemberUseCase {}

class MockLoadContracts extends Mock implements LoadStaffContractsUseCase {}

class MockAddContract extends Mock implements AddStaffContractUseCase {}

class MockCorrectContract extends Mock implements CorrectStaffContractUseCase {}

class MockLoadDossier extends Mock implements LoadStaffDossierUseCase {}

class MockAddDocument extends Mock implements AddStaffDocumentUseCase {}

class MockOpenDocument extends Mock implements OpenStaffDocumentUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// La page agent montée sur des cas d'usage simulés, partagée par les tests
/// de la page : un seul endroit qui sait ce que la page tire de `GetIt`.
class StaffAgentHarness {
  final save = MockSaveMember();
  final load = MockLoadMember();
  final loadContracts = MockLoadContracts();
  final addContract = MockAddContract();
  final correctContract = MockCorrectContract();
  final loadDossier = MockLoadDossier();
  final addDocument = MockAddDocument();
  final openDocument = MockOpenDocument();

  static void registerFallbacks() {
    registerFallbackValue(const StaffMemberDraft(id: 'x'));
    registerFallbackValue(const StaffContractDraft());
    registerFallbackValue(
      const StaffContract(
        id: 'x',
        staffMemberId: 'x',
        kind: null,
        effectiveFrom: 'x',
        recordedAt: 'x',
        syncState: RecordSyncState.synced,
      ),
    );
  }

  /// Enregistre les cas d'usage et les cubits que la page résout, avec des
  /// réponses vides par défaut.
  void register(GetIt getIt) {
    when(
      () => loadDossier(any()),
    ).thenAnswer((_) async => const Right(StaffDossierSnapshot.empty));
    when(() => loadContracts(any())).thenAnswer((_) async => const Right([]));
    getIt
      ..registerSingleton<SaveStaffMemberUseCase>(save)
      ..registerSingleton<LoadStaffMemberUseCase>(load)
      ..registerSingleton<IdGenerator>(const IdGenerator(Uuid()))
      ..registerFactory<StaffDossierCubit>(
        () => StaffDossierCubit(
          load: loadDossier,
          add: addDocument,
          open: openDocument,
        ),
      )
      ..registerFactory<StaffContractsCubit>(
        () => StaffContractsCubit(
          load: loadContracts,
          add: addContract,
          correct: correctContract,
        ),
      );
  }

  /// Monte la page. [permissions] : `null` monte sans session — la porte
  /// laisse alors tout passer ; une liste simule le compte qui les détient.
  Future<void> pump(
    WidgetTester tester, {
    StaffMember? member,
    List<String>? permissions,
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget page = StaffAgentPage(
      member: member,
      kind: member == null ? null : StaffContractKind.permanent,
      others: const [],
      today: '2026-09-29',
    );
    if (permissions != null) {
      final auth = _MockAuthBloc();
      final state = AuthState(
        status: AuthStatus.authenticated,
        permissions: permissions,
      );
      when(() => auth.state).thenReturn(state);
      whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
      page = BlocProvider<AuthBloc>.value(value: auth, child: page);
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );
    await tester.pump();
  }

  /// Ouvre une étape et laisse ses cubits, nés à la première lecture, se
  /// relire puis se peindre.
  static Future<void> openStep(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}
