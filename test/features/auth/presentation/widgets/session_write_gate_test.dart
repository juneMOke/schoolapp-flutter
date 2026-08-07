import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Tests du gel READ_ONLY (ADR-010 D-08, lot H5) : un CTA d'écriture enveloppé
/// dans [SessionWriteGate] doit rester actif en NORMAL/WARNING, devenir inerte
/// en READ_ONLY, et le gate doit être transparent sans [AuthBloc] dans l'arbre
/// (pages métier montées seules en test).
void main() {
  late MockAuthBloc authBloc;
  late int taps;

  setUp(() {
    authBloc = MockAuthBloc();
    taps = 0;
  });

  Widget gatedButton() => SessionWriteGate(
    child: ElevatedButton(onPressed: () => taps++, child: const Text('Écrire')),
  );

  Widget hostWithBloc(AuthState state) {
    whenListen(authBloc, const Stream<AuthState>.empty(), initialState: state);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: Scaffold(body: Center(child: gatedButton())),
      ),
    );
  }

  testWidgets('sans AuthBloc dans l\'arbre : transparent, CTA actif', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: gatedButton())),
      ),
    );
    await tester.tap(find.text('Écrire'));
    expect(taps, 1);
  });

  testWidgets('session NORMAL : CTA actif', (tester) async {
    await tester.pumpWidget(
      hostWithBloc(const AuthState(status: AuthStatus.authenticated)),
    );
    await tester.tap(find.text('Écrire'));
    expect(taps, 1);
  });

  testWidgets('session WARNING : la saisie reste ouverte (D-08)', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostWithBloc(
        const AuthState(
          status: AuthStatus.authenticated,
          sessionMode: SessionMode.warning,
        ),
      ),
    );
    await tester.tap(find.text('Écrire'));
    expect(taps, 1);
  });

  testWidgets('session READ_ONLY : CTA gelé (tap ignoré, estompé)', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostWithBloc(
        const AuthState(
          status: AuthStatus.authenticated,
          sessionMode: SessionMode.readOnly,
        ),
      ),
    );
    await tester.tap(find.text('Écrire'), warnIfMissed: false);
    expect(taps, 0);
    expect(
      find.ancestor(
        of: find.text('Écrire'),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
    expect(
      find.ancestor(of: find.text('Écrire'), matching: find.byType(Opacity)),
      findsWidgets,
    );
  });

  testWidgets('dégèle quand un contact serveur ramène le mode NORMAL', (
    tester,
  ) async {
    const readOnly = AuthState(
      status: AuthStatus.authenticated,
      sessionMode: SessionMode.readOnly,
    );
    const normal = AuthState(status: AuthStatus.authenticated);
    whenListen(
      authBloc,
      Stream<AuthState>.fromIterable(const [normal]),
      initialState: readOnly,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: Scaffold(body: Center(child: gatedButton())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écrire'));
    expect(taps, 1);
  });
}
