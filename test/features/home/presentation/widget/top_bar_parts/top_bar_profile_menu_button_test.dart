import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_profile_menu_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// « Paramètres » du menu du compte est la troisième porte vers les réglages de
/// l'école, avec la barre latérale et la grille d'accueil. Ce qu'on vérifie
/// ici : qu'elle mène au même endroit **dans la coquille**, et qu'elle est
/// fermée exactement comme les deux autres.
void main() {
  late _MockAuthBloc authBloc;
  late NavigationBloc navigationBloc;

  Future<void> pumpMenu(
    WidgetTester tester, {
    required List<String> permissions,
  }) async {
    authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            navigationBloc = NavigationBloc(
              AppLocalizations.of(context)!,
              permissions: permissions,
            );
            addTearDown(navigationBloc.close);
            return MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: authBloc),
                BlocProvider<NavigationBloc>.value(value: navigationBloc),
              ],
              child: const Scaffold(
                body: Center(child: TopBarProfileMenuButton()),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TopBarProfileMenuButton));
    await tester.pumpAndSettle();
  }

  const droitDeReglage = 'school.provisioning.write';

  testWidgets('avec le droit : « Paramètres » bascule la coquille sur les '
      'réglages', (tester) async {
    await pumpMenu(tester, permissions: const [droitDeReglage]);

    expect(find.text('Paramètres'), findsOneWidget);

    await tester.tap(find.text('Paramètres'));
    await tester.pumpAndSettle();

    // La coquille a changé d'écran, et le titre suit : c'est ce que le fil
    // d'Ariane et la barre latérale liront. Un `context.go` aurait quitté la
    // coquille et laissé ces deux-là sur l'écran précédent.
    expect(
      navigationBloc.state.selectedSubMenuId,
      MenuConstants.configurationSchoolId,
    );
    expect(
      navigationBloc.state.selectedMenuId,
      MenuConstants.configurationMenuId,
    );
    expect(navigationBloc.state.currentTitle, 'Paramètres de l\'école');
  });

  testWidgets('sans le droit : l\'entrée disparaît, le reste du menu tient', (
    tester,
  ) async {
    await pumpMenu(tester, permissions: const ['enrollment.read']);

    expect(find.text('Paramètres'), findsNothing);
    // Contre-épreuve : le menu s'est bien ouvert. Sans elle, une popin qui ne
    // s'ouvre pas ferait passer l'assertion ci-dessus sans rien prouver.
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);
  });
}
