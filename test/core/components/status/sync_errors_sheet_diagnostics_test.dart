import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/sync_errors_sheet.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/pull_diagnostic.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _FakeSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  _FakeSyncStatusCubit(super.initialState);

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOutboxErrorsCubit extends Cubit<OutboxErrorsState>
    implements OutboxErrorsCubit {
  _FakeOutboxErrorsCubit()
    : super(const OutboxErrorsState(status: OutboxErrorsStatus.loaded));

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// La session locale, réduite au rôle — seul champ que la feuille consulte.
class _FakeAuthLocalDao implements AuthLocalDao {
  final String role;

  _FakeAuthLocalDao(this.role);

  @override
  Future<AuthLocalUserRecord?> getSessionUser() async => AuthLocalUserRecord(
    userId: 'u',
    email: 'u@eteelo.cd',
    firstName: 'U',
    lastName: 'U',
    role: role,
    schoolId: 's',
    passwordVerifier: '',
    verifierSalt: '',
    userVersion: 0,
    firstOnlineLoginAt: 0,
    lastServerSeenAt: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _ligne = 'finance_payments — Échec : timeout 12 s';

void main() {
  setUp(() {
    getIt.registerFactory<OutboxErrorsCubit>(_FakeOutboxErrorsCubit.new);
    getIt.registerSingleton<CurrentUserContext>(CurrentUserContext()..set('u'));
  });

  tearDown(() => getIt.reset());

  Future<void> ouvrir(WidgetTester tester, String role) async {
    getIt.registerSingleton<AuthLocalDao>(_FakeAuthLocalDao(role));
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final cubit = _FakeSyncStatusCubit(
      const SyncStatusState(
        status: SyncStatus.partiallySynced,
        hasIncompleteRead: true,
        readDiagnostics: [
          PullDiagnostic(
            'finance_payments',
            PullDiagnosticKind.failed,
            detail: 'timeout 12 s',
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSyncErrorsSheet(context),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('un super-administrateur voit les flux en défaut', (
    tester,
  ) async {
    await ouvrir(tester, 'SUPER_ADMIN');
    expect(find.text('Flux en défaut'), findsOneWidget);
    expect(find.text(_ligne), findsOneWidget);
  });

  testWidgets('un autre rôle ne voit que le bandeau', (tester) async {
    await ouvrir(tester, 'DIRECTOR');
    expect(find.text('Certaines données ne descendent pas'), findsOneWidget);
    expect(find.text('Flux en défaut'), findsNothing);
    expect(find.text(_ligne), findsNothing);
  });
}
