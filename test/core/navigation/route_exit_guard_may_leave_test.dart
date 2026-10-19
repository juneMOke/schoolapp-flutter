import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/bloc_exit_guard.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une sortie décidée dans la page (écran du menu, retour d'un écran à
/// niveaux) : l'écran gardé disparaît AVANT que l'adresse ne change, et
/// `onExit` n'aurait plus personne à qui demander. `mayLeave` demande avant.
void main() {
  late bool dirty;
  late int asked;
  late bool answer;

  setUp(() {
    dirty = false;
    asked = 0;
    answer = false;
  });

  Future<GoRouter> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/coquille/notes',
      routes: [
        GoRoute(
          path: '/coquille/:ecran',
          onExit: RouteExitGuard.onExitOfPage(const ValueKey('coquille')),
          pageBuilder: (_, state) => MaterialPage(
            key: const ValueKey('coquille'),
            child: _Shell(
              screen: state.pathParameters['ecran']!,
              guarded: (child) => RouteExitGuard(
                hasUnsavedWork: () => dirty,
                confirmExit: () async {
                  asked++;
                  return answer;
                },
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.text('menu : accueil'));
    await tester.pumpAndSettle();
  }

  bool onNotes() => find.text('saisie').evaluate().isNotEmpty;

  testWidgets('rien de saisi : le menu change d\'écran sans question', (
    tester,
  ) async {
    await pump(tester);
    await openMenu(tester);
    expect(asked, 0);
    expect(onNotes(), isFalse);
  });

  testWidgets('une saisie : « rester » garde l\'écran et son adresse', (
    tester,
  ) async {
    dirty = true;
    final router = await pump(tester);
    await openMenu(tester);
    expect(asked, 1);
    expect(onNotes(), isTrue);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/coquille/notes',
    );
  });

  testWidgets('une saisie : « partir » change d\'écran, une seule question', (
    tester,
  ) async {
    dirty = true;
    answer = true;
    await pump(tester);
    await openMenu(tester);
    // La garde levée par `mayLeave` ne repose pas la question quand
    // l'adresse change ensuite (`onExit`).
    expect(asked, 1);
    expect(onNotes(), isFalse);
  });

  testWidgets('rien de saisi au moment du geste : la garde reste armée', (
    tester,
  ) async {
    // Le geste vers le même écran ne le quitte pas : la saisie qui suit doit
    // encore poser la question.
    final router = await pump(tester);
    final context = tester.element(find.text('saisie'));
    expect(await RouteExitGuard.mayLeave(context), isTrue);
    dirty = true;
    router.go('/coquille/accueil');
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(onNotes(), isTrue);
  });

  group('BlocExitGuard', () {
    Future<_DraftCubit> pumpBloc(WidgetTester tester) async {
      final cubit = _DraftCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: BlocProvider.value(
            value: cubit,
            child: BlocExitGuard<_DraftCubit, int>(
              hasUnsavedWork: (count) => count > 0,
              discardMessage: 'Le panier sera vidé.',
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => RouteExitGuard.mayLeave(context),
                  child: const Text('partir'),
                ),
              ),
            ),
          ),
        ),
      );
      return cubit;
    }

    testWidgets('sans saisie, aucune question', (tester) async {
      await pumpBloc(tester);
      await tester.tap(find.text('partir'));
      await tester.pumpAndSettle();
      expect(find.text('Le panier sera vidé.'), findsNothing);
    });

    testWidgets('la saisie lue dans le bloc pose la question, avec son '
        'message', (tester) async {
      final cubit = await pumpBloc(tester);
      cubit.add();
      await tester.pump();
      await tester.tap(find.text('partir'));
      await tester.pumpAndSettle();
      expect(find.text('Le panier sera vidé.'), findsOneWidget);
      expect(find.text('Abandonner les modifications ?'), findsOneWidget);
    });
  });
}

class _DraftCubit extends Cubit<int> {
  _DraftCubit() : super(0);

  void add() => emit(state + 1);
}

/// Une coquille minimale : un menu, et l'écran choisi — l'écran disparaît
/// dès la sélection, l'adresse suit ensuite (comme `ShellLocationSync`).
class _Shell extends StatefulWidget {
  final String screen;
  final Widget Function(Widget child) guarded;

  const _Shell({required this.screen, required this.guarded});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  late String _screen = widget.screen;

  Future<void> _select(BuildContext context, String screen) async {
    if (!await RouteExitGuard.mayLeave(context) || !context.mounted) return;
    setState(() => _screen = screen);
    context.go('/coquille/$screen');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Builder(
          builder: (context) => TextButton(
            onPressed: () => _select(context, 'accueil'),
            child: const Text('menu : accueil'),
          ),
        ),
        if (_screen == 'notes')
          widget.guarded(const Text('saisie'))
        else
          Text(_screen),
      ],
    ),
  );
}
