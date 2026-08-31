import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Cubit de synchro piloté par le test : la barre ne fait que lire son état.
class _FakeSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  _FakeSyncStatusCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;

  setUp(() {
    authBloc = _MockAuthBloc();
    // Le menu du compte lit les permissions pour décider d'offrir
    // « Paramètres ». Ces tests portent sur la pastille de synchro : un porteur
    // sans droit suffit, et laisse cette entrée hors du chemin.
    const authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: <String>[],
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );
  });

  Future<void> pumpActions(
    WidgetTester tester, {
    required SyncStatus status,
    bool hasHeldWork = false,
    bool hasIncompleteRead = false,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SyncStatusCubit>(
              // Clé discriminante : un second `pumpWidget` dans le MÊME test
              // réutilise l'élément, et `BlocProvider` ne rejoue alors jamais
              // son `create` — la nouvelle graine n'atteindrait pas l'arbre, et
              // l'assertion passerait grâce à l'état du pump précédent.
              key: ValueKey((status, hasHeldWork, hasIncompleteRead)),
              create: (_) => _FakeSyncStatusCubit(
                SyncStatusState(
                  status: status,
                  hasHeldWork: hasHeldWork,
                  hasIncompleteRead: hasIncompleteRead,
                ),
              ),
            ),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const Scaffold(body: TopBarActions(isCompact: false)),
        ),
      ),
    );
    await tester.pump();
  }

  /// Le geste d'ouverture de la feuille, tel que la pastille l'expose.
  VoidCallback? tapHandler(WidgetTester tester) =>
      tester.widget<SyncIndicator>(find.byType(SyncIndicator)).onTap;

  testWidgets('lecture incomplète : la pastille est TAPABLE', (tester) async {
    await pumpActions(
      tester,
      // Ni conflit ni travail retenu : la lecture incomplète est, à elle
      // seule, ce qui doit ouvrir la feuille. Sans cela « Partiellement à
      // jour » annoncerait un manque sans jamais dire lequel — un cul-de-sac.
      status: SyncStatus.partiallySynced,
      hasIncompleteRead: true,
    );

    expect(find.text('Partiellement à jour'), findsOneWidget);
    expect(tapHandler(tester), isNotNull);
  });

  testWidgets(
    'lecture incomplète masquée par « À envoyer » : toujours TAPABLE',
    (tester) async {
      // Le drapeau est porté à part du statut précisément pour ce cas : la
      // pastille dit la condition la plus urgente, mais la porte reste ouverte
      // sur l'autre chose que la feuille a à dire.
      await pumpActions(
        tester,
        status: SyncStatus.pendingUpload,
        hasIncompleteRead: true,
      );

      expect(tapHandler(tester), isNotNull);
    },
  );

  testWidgets('rien à signaler : la pastille n\'est pas tapable', (
    tester,
  ) async {
    await pumpActions(tester, status: SyncStatus.synced);

    // Contre-épreuve : sans elle, un `onTap` posé inconditionnellement
    // ferait passer le test précédent sans rien prouver.
    expect(tapHandler(tester), isNull);
  });

  testWidgets('les deux autres portes d\'entrée restent ouvertes', (
    tester,
  ) async {
    await pumpActions(tester, status: SyncStatus.syncConflict);
    expect(tapHandler(tester), isNotNull);

    await pumpActions(
      tester,
      status: SyncStatus.pendingUpload,
      hasHeldWork: true,
    );
    expect(tapHandler(tester), isNotNull);
  });
}
