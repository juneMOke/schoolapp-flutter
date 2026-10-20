import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';

/// Les gardes des écrans de la COQUILLE : une seule page pour toutes ses
/// adresses (`onExitOfPage`), des écrans qui disparaissent dès la sélection,
/// et des pages sans route poussées par-dessus.
void main() {
  late int asked;
  late bool answer;
  late bool busy;

  setUp(() {
    asked = 0;
    answer = true;
    busy = false;
  });

  Widget guarded(Widget child) => RouteExitGuard(
    hasUnsavedWork: () => true,
    isBusy: () => busy,
    confirmExit: () async {
      asked++;
      return answer;
    },
    child: child,
  );

  GoRouter shellRouter(
    Widget Function(BuildContext context, String screen) screen, {
    Listenable? refresh,
    GoRouterRedirect? redirect,
  }) {
    final router = GoRouter(
      initialLocation: '/c/notes',
      refreshListenable: refresh,
      redirect: redirect,
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const Text('connexion')),
        GoRoute(
          path: '/c/:ecran',
          onExit: RouteExitGuard.onExitOfPage(const ValueKey('coquille')),
          pageBuilder: (_, state) => MaterialPage(
            key: const ValueKey('coquille'),
            child: Builder(
              builder: (context) => Scaffold(
                body: screen(context, state.pathParameters['ecran']!),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  String path(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('la réponse arrive après le départ de l\'écran : ni exception, '
      'et l\'adresse suit', (tester) async {
    // Sélection par le bloc sans `mayLeave` : l'adresse change pendant que
    // l'écran est encore là (la question part), puis il est remplacé avant
    // la réponse.
    final cubit = _ScreenCubit('notes');
    addTearDown(cubit.close);
    final router = shellRouter(
      (context, _) => BlocProvider.value(
        value: cubit,
        child: BlocConsumer<_ScreenCubit, String>(
          listener: (context, screen) => context.go('/c/$screen'),
          builder: (_, screen) =>
              screen == 'notes' ? guarded(const Text('saisie')) : Text(screen),
        ),
      ),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    cubit.emit('accueil');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(path(router), '/c/accueil');
  });

  testWidgets('une garde levée dont l\'écran reste affiché se réarme', (
    tester,
  ) async {
    final router = shellRouter((_, _) => guarded(const Text('saisie')));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('saisie'));
    // « Abandonner » accordé… mais rien ne part (déconnexion échouée).
    expect(await RouteExitGuard.mayLeave(context), isTrue);
    expect(asked, 1);
    await tester.pump();
    router.go('/c/accueil');
    await tester.pumpAndSettle();
    expect(asked, 2);
  });

  testWidgets('partir referme aussi les pages sans route poussées au-dessus '
      'de l\'écran gardé', (tester) async {
    final router = shellRouter(
      (context, screen) => screen == 'notes'
          ? guarded(
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('panier')),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            )
          : Text(screen),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    router.go('/c/accueil');
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(find.text('panier'), findsNothing);
    expect(find.text('accueil'), findsOneWidget);
  });

  testWidgets('une déconnexion forcée passe avant une écriture en vol', (
    tester,
  ) async {
    busy = true;
    final auth = _Auth();
    addTearDown(auth.dispose);
    final router = shellRouter(
      (_, _) => guarded(const Text('saisie')),
      refresh: auth,
      redirect: (_, state) =>
          !auth.loggedIn && state.matchedLocation != '/login' ? '/login' : null,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    auth.logout();
    await tester.pumpAndSettle();
    expect(find.text('connexion'), findsOneWidget);
    expect(asked, 0);
  });
}

class _ScreenCubit extends Cubit<String> {
  _ScreenCubit(super.initialState);

  @override
  void emit(String state) => super.emit(state);
}

class _Auth extends ChangeNotifier {
  bool loggedIn = true;

  void logout() {
    loggedIn = false;
    RouteExitGuard.duringRouterRefresh(notifyListeners);
  }
}
