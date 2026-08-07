import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_degradation_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Tests du bandeau global de dégradation (ADR-010 D-08, lot G9/H4).
///
/// Le bandeau est monté au-dessus des routes : il doit être ABSENT en session
/// online NORMAL (aucun décalage de layout), et afficher le bon message pour
/// offline-NORMAL / WARNING / READ_ONLY.
void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
  });

  Widget host() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const SessionDegradationBanner(
        child: Scaffold(body: Text('contenu')),
      ),
    ),
  );

  Future<AppLocalizations> pumpWithState(
    WidgetTester tester,
    AuthState state,
  ) async {
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: state);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.text('contenu')))!;
  }

  testWidgets('aucun bandeau hors session (page de login)', (tester) async {
    final l10n = await pumpWithState(
      tester,
      const AuthState(status: AuthStatus.unauthenticated),
    );
    expect(find.text('contenu'), findsOneWidget);
    expect(find.text(l10n.sessionOfflineBanner), findsNothing);
    expect(find.text(l10n.sessionWarningBanner), findsNothing);
    expect(find.text(l10n.sessionReadOnlyBanner), findsNothing);
  });

  testWidgets('aucun bandeau en session online NORMAL', (tester) async {
    final l10n = await pumpWithState(
      tester,
      const AuthState(status: AuthStatus.authenticated),
    );
    expect(find.text(l10n.sessionOfflineBanner), findsNothing);
    expect(find.text(l10n.sessionWarningBanner), findsNothing);
    expect(find.text(l10n.sessionReadOnlyBanner), findsNothing);
  });

  testWidgets('session offline NORMAL → rappel discret hors-ligne', (
    tester,
  ) async {
    final l10n = await pumpWithState(
      tester,
      const AuthState(status: AuthStatus.authenticated, isOffline: true),
    );
    expect(find.text(l10n.sessionOfflineBanner), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('mode WARNING → bandeau ambre permanent', (tester) async {
    final l10n = await pumpWithState(
      tester,
      const AuthState(
        status: AuthStatus.authenticated,
        sessionMode: SessionMode.warning,
      ),
    );
    expect(find.text(l10n.sessionWarningBanner), findsOneWidget);
    // WARNING prime sur le rappel offline (un seul bandeau à la fois).
    expect(find.text(l10n.sessionOfflineBanner), findsNothing);
  });

  testWidgets('mode READ_ONLY → bandeau lecture seule', (tester) async {
    final l10n = await pumpWithState(
      tester,
      const AuthState(
        status: AuthStatus.authenticated,
        sessionMode: SessionMode.readOnly,
        isOffline: true,
      ),
    );
    expect(find.text(l10n.sessionReadOnlyBanner), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('le bandeau suit les transitions de mode du bloc', (
    tester,
  ) async {
    const warning = AuthState(
      status: AuthStatus.authenticated,
      sessionMode: SessionMode.warning,
    );
    whenListen(
      authBloc,
      Stream<AuthState>.fromIterable(const [warning]),
      initialState: const AuthState(status: AuthStatus.authenticated),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.text('contenu')))!;
    expect(find.text(l10n.sessionWarningBanner), findsOneWidget);
  });
}
