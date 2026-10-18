import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell_location_sync.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Chaque écran de la coquille a son adresse, et l'adresse son écran.
///
/// Avant, tout vivait sous `/home` : Précédent sortait de l'application, F5
/// ramenait à l'Accueil et un lien copié ne menait nulle part.
void main() {
  const permissions = ['finance.charge.read', 'classroom.read'];
  late GoRouter router;
  late int shellsBuilt;

  /// La coquille réduite à ce qui compte ici — même montage que `HomePage`.
  Page<void> shell(String? subMenuId) => MaterialPage<void>(
    key: const ValueKey('home-shell'),
    child: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return BlocProvider(
          create: (_) {
            shellsBuilt++;
            final bloc = NavigationBloc(l10n, permissions: permissions);
            ShellLocationSync.select(bloc, subMenuId, l10n);
            return bloc;
          },
          child: ShellLocationSync(
            subMenuId: subMenuId,
            child: Scaffold(
              body: BlocBuilder<NavigationBloc, NavigationState>(
                builder: (context, state) => Column(
                  children: [
                    Text('écran:${state.selectedSubMenuId}'),
                    TextButton(
                      onPressed: () => context.read<NavigationBloc>().add(
                        const SubMenuItemSelected(
                          menuId: 'classes',
                          subMenuId: MenuConstants.classesListId,
                          title: 'Classes',
                        ),
                      ),
                      child: const Text('menu:classes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Future<void> pump(WidgetTester tester, String initial) async {
    shellsBuilt = 0;
    router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: AppRoutesNames.homePath,
          pageBuilder: (_, _) => shell(null),
        ),
        GoRoute(
          path: AppRoutesNames.homeSubMenuRoute,
          pageBuilder: (_, state) => shell(state.pathParameters['subMenuId']),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('une adresse ouvre son écran (F5, lien partagé)', (tester) async {
    await pump(tester, '/home/${MenuConstants.facturationsId}');
    expect(find.text('écran:${MenuConstants.facturationsId}'), findsOneWidget);
    expect(location(), '/home/${MenuConstants.facturationsId}');
  });

  testWidgets('choisir un écran au menu écrit son adresse', (tester) async {
    await pump(tester, '/home');
    await tester.tap(find.text('menu:classes'));
    await tester.pumpAndSettle();

    expect(location(), '/home/${MenuConstants.classesListId}');
    expect(find.text('écran:${MenuConstants.classesListId}'), findsOneWidget);
    expect(shellsBuilt, 1, reason: 'la coquille est mise à jour, pas refaite');
  });

  testWidgets('une adresse qui change (Précédent) ramène son écran', (
    tester,
  ) async {
    await pump(tester, '/home/${MenuConstants.classesListId}');
    router.go('/home/${MenuConstants.facturationsId}');
    await tester.pumpAndSettle();
    expect(find.text('écran:${MenuConstants.facturationsId}'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('écran:${MenuConstants.accueilId}'), findsOneWidget);
    expect(shellsBuilt, 1);
  });

  testWidgets('un écran hors des droits retombe sur l\'Accueil', (
    tester,
  ) async {
    await pump(tester, '/home/${MenuConstants.expenseRegisterId}');
    expect(find.text('écran:${MenuConstants.accueilId}'), findsOneWidget);
  });
}
