import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login_form.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_back_link.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/reset/reset_stepper_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockForgotPasswordBloc
    extends MockBloc<ForgotPasswordEvent, ForgotPasswordState>
    implements ForgotPasswordBloc {}

void main() {
  late MockAuthBloc authBloc;
  late MockForgotPasswordBloc forgotPasswordBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    forgotPasswordBloc = MockForgotPasswordBloc();
  });

  Widget buildLocalizedHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Widget buildAuthHarness(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ForgotPasswordBloc>.value(value: forgotPasswordBloc),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('AuthErrorBanner exposes an alert-like live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuthErrorBanner(message: 'Erreur de connexion')),
        ),
      );

      expect(find.bySemanticsLabel('Erreur de connexion'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('ResetBackLink uses an accessible button for back action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildLocalizedHarness(const ResetBackLink()));

    expect(find.byType(TextButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets(
    'ResetStepperHeader announces the current step as a live region',
    (tester) async {
      final handle = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          buildLocalizedHarness(const ResetStepperHeader(currentStep: 1)),
        );

        expect(find.bySemanticsLabel('Étape 1 sur 3 · E-mail'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets('LoginForm provides focus traversal and autofill grouping', (
    tester,
  ) async {
    final authState = AuthState.initial();
    final forgotState = const ForgotPasswordState.initial();

    when(() => authBloc.state).thenReturn(authState);
    when(() => forgotPasswordBloc.state).thenReturn(forgotState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );
    whenListen(
      forgotPasswordBloc,
      Stream<ForgotPasswordState>.value(forgotState),
      initialState: forgotState,
    );

    await tester.pumpWidget(buildAuthHarness(const LoginForm()));

    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });
}
