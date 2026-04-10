import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_email_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/forgot_password_otp_page.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/reset_password_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import '../../../../test_helpers/widget_test_utils.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockForgotPasswordBloc
    extends MockBloc<ForgotPasswordEvent, ForgotPasswordState>
    implements ForgotPasswordBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc authBloc;
  late MockForgotPasswordBloc forgotPasswordBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    forgotPasswordBloc = MockForgotPasswordBloc();
  });

  Widget buildHarness(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ForgotPasswordBloc>.value(value: forgotPasswordBloc),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await pumpBounded(tester, buildHarness(page));
  }

  void stubBlocs({
    required AuthState authState,
    required ForgotPasswordState forgotState,
  }) {
    when(() => authBloc.state).thenReturn(authState);
    when(() => forgotPasswordBloc.state).thenReturn(forgotState);
    whenListen(authBloc, Stream<AuthState>.value(authState), initialState: authState);
    whenListen(
      forgotPasswordBloc,
      Stream<ForgotPasswordState>.value(forgotState),
      initialState: forgotState,
    );
  }

  testWidgets('Forgot password email page renders on narrow mobile viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    stubBlocs(
      authState: AuthState.initial(),
      forgotState: const ForgotPasswordState.initial(),
    );

    await pumpPage(tester, const ForgotPasswordEmailPage());

    expect(find.byType(ForgotPasswordEmailPage), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Forgot password email page renders on desktop low height', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 420));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    stubBlocs(
      authState: AuthState.initial(),
      forgotState: const ForgotPasswordState.initial(),
    );

    await pumpPage(tester, const ForgotPasswordEmailPage());

    expect(find.byType(ForgotPasswordEmailPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Forgot password OTP page renders with email context', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    stubBlocs(
      authState: AuthState.initial(),
      forgotState: const ForgotPasswordState(
        status: ForgotPasswordStatus.otpGenerated,
        userEmail: 'test@example.com',
      ),
    );

    await pumpPage(tester, const ForgotPasswordOtpPage());

    expect(find.byType(ForgotPasswordOtpPage), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reset password page renders with email and reset token', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    stubBlocs(
      authState: AuthState.initial(),
      forgotState: const ForgotPasswordState(
        status: ForgotPasswordStatus.otpValidated,
        userEmail: 'test@example.com',
        resetToken: 'token-123',
      ),
    );

    await pumpPage(tester, const ResetPasswordPage());

    expect(find.byType(ResetPasswordPage), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}