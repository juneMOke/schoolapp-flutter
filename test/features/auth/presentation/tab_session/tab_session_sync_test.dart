import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/web/tab_channel/tab_channel.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/tab_session/tab_session_message.dart';
import 'package:school_app_flutter/features/auth/presentation/tab_session/tab_session_sync.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _FakeChannel implements TabChannel {
  final incoming = StreamController<String>.broadcast();
  final posted = <String>[];

  @override
  Stream<String> get messages => incoming.stream;

  @override
  void post(String message) => posted.add(message);

  @override
  void close() => unawaited(incoming.close());
}

AuthState _signedIn(String id) => AuthState(
  status: AuthStatus.authenticated,
  user: AuthenticatedUser(
    id: id,
    email: '$id@ecole.cd',
    firstName: 'Agent',
    lastName: id,
    role: 'CASHIER',
    schoolId: 'ecole',
  ),
);

const _signedOut = AuthState(status: AuthStatus.unauthenticated);

void main() {
  late _MockAuthBloc auth;
  late _FakeChannel channel;
  late StreamController<AuthState> states;

  setUpAll(() => registerFallbackValue(const AuthSessionEndedElsewhere()));

  setUp(() {
    auth = _MockAuthBloc();
    channel = _FakeChannel();
    states = StreamController<AuthState>.broadcast();
    addTearDown(states.close);
  });

  Future<void> pump(WidgetTester tester, AuthState initial) async {
    whenListen(auth, states.stream, initialState: initial);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: TabSessionSync(
          openChannel: () => channel,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<void> receive(WidgetTester tester, TabSessionMessage message) async {
    channel.incoming.add(message.encode());
    await tester.pump();
  }

  testWidgets('une déconnexion ailleurs ramène cet onglet à la connexion', (
    tester,
  ) async {
    await pump(tester, _signedIn('a'));
    await receive(tester, const TabSignedOut());
    verify(() => auth.add(const AuthSessionEndedElsewhere())).called(1);
  });

  testWidgets('un AUTRE agent connecté ailleurs : cet onglet sort ; le même '
      'agent : rien', (tester) async {
    await pump(tester, _signedIn('a'));
    await receive(tester, const TabSignedIn('a'));
    verifyNever(() => auth.add(any()));
    await receive(tester, const TabSignedIn('b'));
    verify(() => auth.add(const AuthSessionEndedElsewhere())).called(1);
  });

  testWidgets('sans session, cet onglet n\'écoute rien et n\'annonce rien', (
    tester,
  ) async {
    await pump(tester, _signedOut);
    await receive(tester, const TabSignedOut());
    verifyNever(() => auth.add(any()));
    // Un onglet qui s'ouvre sans session ne déconnecte personne.
    states.add(_signedOut);
    await tester.pump();
    expect(channel.posted, isEmpty);
  });

  testWidgets('connexion puis déconnexion de cet onglet : annoncées', (
    tester,
  ) async {
    await pump(tester, const AuthState(status: AuthStatus.loading));
    states.add(_signedIn('a'));
    await tester.pump();
    states.add(const AuthState(status: AuthStatus.loading));
    await tester.pump();
    states.add(_signedOut);
    await tester.pump();
    expect(channel.posted.map(TabSessionMessage.decode).toList(), [
      isA<TabSignedIn>().having((m) => m.userId, 'userId', 'a'),
      isA<TabSignedOut>(),
    ]);
  });

  testWidgets('une fin de session venue d\'ailleurs n\'est pas renvoyée', (
    tester,
  ) async {
    await pump(tester, const AuthState(status: AuthStatus.loading));
    states.add(_signedIn('a'));
    await tester.pump();
    channel.posted.clear();
    await receive(tester, const TabSignedIn('b'));
    states.add(_signedOut);
    await tester.pump();
    // Sinon l'onglet où « b » vient de se connecter serait déconnecté.
    expect(channel.posted, isEmpty);
  });

  test('un message illisible ne veut rien dire', () {
    expect(TabSessionMessage.decode('pas du json'), isNull);
    expect(TabSessionMessage.decode('{"type":"inconnu"}'), isNull);
    expect(TabSessionMessage.decode('{"type":"signedIn"}'), isNull);
  });
}
