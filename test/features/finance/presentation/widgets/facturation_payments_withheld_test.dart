import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_data_loader.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_payments_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockPaymentsBloc extends MockBloc<PaymentsEvent, PaymentsState>
    implements PaymentsBloc {}

class _MockChargesBloc
    extends MockBloc<StudentChargesEvent, StudentChargesState>
    implements StudentChargesBloc {}

/// ADR-015 §6-C — séparation charge / caisse. Le secrétariat, la direction des
/// études et la discipline détiennent `finance.charge.read` SANS
/// `finance.payment.read` (`role_journeys_test.dart`). Ils lisaient pourtant, sur
/// la même fiche : « Payé : 50 000 FC » dans le bandeau, et juste dessous
/// « Aucun paiement n'a été enregistré pour cet élève ».
///
/// Le correctif n'est PAS d'entraîner le flux paiements — ce serait détruire la
/// séparation qu'ADR-014 a créée. La section se tait : elle ne sait pas.
void main() {
  setUpAll(() {
    registerFallbackValue(
      const PaymentsRequested(studentId: 's1', academicYearId: 'ay1'),
    );
    registerFallbackValue(
      const StudentChargesByAcademicYearRequested(
        studentId: 's1',
        academicYearId: 'ay1',
      ),
    );
  });

  const caissier = <String>['finance.charge.read', 'finance.payment.read'];
  const secretariat = <String>['finance.charge.read'];

  late _MockPaymentsBloc paymentsBloc;
  late _MockChargesBloc chargesBloc;

  setUp(() {
    paymentsBloc = _MockPaymentsBloc();
    const paymentsState = PaymentsState();
    when(() => paymentsBloc.state).thenReturn(paymentsState);
    whenListen(
      paymentsBloc,
      const Stream<PaymentsState>.empty(),
      initialState: paymentsState,
    );

    chargesBloc = _MockChargesBloc();
    const chargesState = StudentChargesState();
    when(() => chargesBloc.state).thenReturn(chargesState);
    whenListen(
      chargesBloc,
      const Stream<StudentChargesState>.empty(),
      initialState: chargesState,
    );
  });

  Widget host(List<String> permissions, Widget child) {
    final authBloc = _MockAuthBloc();
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

    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<PaymentsBloc>.value(value: paymentsBloc),
              BlocProvider<StudentChargesBloc>.value(value: chargesBloc),
            ],
            child: child,
          ),
        ),
      ),
    );
  }

  Widget section() => FacturationDetailPaymentsSection(
    studentId: 's1',
    academicYearId: 'ay1',
    onCreatePaymentRequested: () {},
    onViewPaymentRequested: (_) {},
  );

  group('section Versements', () {
    testWidgets('sans finance.payment.read : la section se tait', (
      tester,
    ) async {
      await tester.pumpWidget(host(secretariat, section()));
      await tester.pump();

      expect(find.byKey(const ValueKey('payments-withheld')), findsOneWidget);
      // Surtout PAS le vide affirmatif.
      expect(find.byKey(const ValueKey('payments-empty')), findsNothing);
    });

    testWidgets('avec finance.payment.read : le vide reste une information', (
      tester,
    ) async {
      await tester.pumpWidget(host(caissier, section()));
      await tester.pump();

      expect(find.byKey(const ValueKey('payments-withheld')), findsNothing);
      expect(find.byKey(const ValueKey('payments-empty')), findsOneWidget);
    });
  });

  group('chargement des données', () {
    Widget loader() => const FacturationDetailDataLoader(
      intent: FacturationDetailIntent.invalid(
        studentId: 's1',
        academicYearId: 'ay1',
      ),
      child: SizedBox.shrink(),
    );

    testWidgets(
      'sans finance.payment.read : les paiements ne sont pas demandés',
      (tester) async {
        await tester.pumpWidget(host(secretariat, loader()));
        await tester.pump();

        verifyNever(() => paymentsBloc.add(any()));
        // Les créances, elles, sont bien demandées : le profil y a droit.
        verify(() => chargesBloc.add(any())).called(1);
      },
    );

    testWidgets('avec finance.payment.read : les deux sont demandés', (
      tester,
    ) async {
      await tester.pumpWidget(host(caissier, loader()));
      await tester.pump();

      verify(() => paymentsBloc.add(any())).called(1);
      verify(() => chargesBloc.add(any())).called(1);
    });
  });
}
