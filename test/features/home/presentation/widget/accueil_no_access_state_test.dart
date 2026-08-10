import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/pages/accueil_page.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_brand_banner.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_module_card.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_no_access_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// ADR-014 §2.8 — le fail-closed produit une grille vide dans trois cas : rôle
/// délibérément sans droits, compte dépouillé, et compte pas encore reconnecté
/// en ligne après une mise à jour. Sans écran dédié, les trois se lisent comme
/// une panne.
void main() {
  late _MockAuthBloc authBloc;

  Widget buildHarness({
    required List<String> permissions,
    bool isOffline = false,
  }) {
    authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
      isOffline: isOffline,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<NavigationBloc>(
              create: (_) => NavigationBloc(
                AppLocalizations.of(context)!,
                permissions: permissions,
              ),
            ),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const AccueilPage(),
        ),
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required List<String> permissions,
    bool isOffline = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildHarness(permissions: permissions, isOffline: isOffline),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('aucun droit : l\'état remplace la grille', (tester) async {
    await pump(tester, permissions: const []);

    expect(find.byType(AccueilNoAccessState), findsOneWidget);
    expect(find.byType(AccueilModuleCard), findsNothing);
    expect(find.text('Aucun module accessible'), findsOneWidget);
  });

  // Le bandeau porte le nom de l'école et la salutation : ce qui situe
  // l'utilisateur doit rester, même quand il n'a accès à rien.
  testWidgets('le bandeau de marque survit à l\'état vide', (tester) async {
    await pump(tester, permissions: const []);

    expect(find.byType(AccueilBrandBanner), findsOneWidget);
  });

  // Anatomie 403 : rien à réessayer, la réponse du serveur ne changera pas
  // parce qu'on la redemande.
  testWidgets('aucun « Réessayer » n\'est proposé', (tester) async {
    await pump(tester, permissions: const []);

    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('session en ligne : la déconnexion est offerte', (tester) async {
    await pump(tester, permissions: const []);

    expect(find.text('Se déconnecter'), findsOneWidget);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pump();

    verify(() => authBloc.add(const AuthLogoutRequested())).called(1);
  });

  // Hors ligne, se déconnecter ferait perdre la session sans pouvoir en rouvrir
  // une : le bouton serait un piège. On explique quoi faire, sans l'offrir.
  testWidgets('session hors ligne : message dédié, aucune action', (
    tester,
  ) async {
    await pump(tester, permissions: const [], isOffline: true);

    expect(find.byType(AccueilNoAccessState), findsOneWidget);
    expect(find.textContaining('hors ligne'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsNothing);
  });

  testWidgets('un seul droit suffit à retrouver la grille', (tester) async {
    await pump(tester, permissions: const ['classroom.read']);

    expect(find.byType(AccueilNoAccessState), findsNothing);
    expect(find.byType(AccueilModuleCard), findsOneWidget);
  });

  // Fail-closed : une permission que cette version de l'application ne connaît
  // pas ne débloque rien, donc l'état reste affiché.
  testWidgets('une permission inconnue ne débloque pas la grille', (
    tester,
  ) async {
    await pump(tester, permissions: const ['module.futur.read']);

    expect(find.byType(AccueilNoAccessState), findsOneWidget);
  });
}
