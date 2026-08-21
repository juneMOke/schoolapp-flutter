import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_revalidation_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_allocations_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_detail_dialog.dart';
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

class _FakeRevalidationCubit extends Cubit<int>
    implements LedgerRevalidationCubit {
  _FakeRevalidationCubit() : super(0);

  @override
  void watch(String studentId) {}
}

/// M-2 / M-3 — **`null` n'est pas `[]`**, et la Facturation le confondait.
///
/// `PermissionGate.allows` répond `false` sur un ensemble de permissions encore
/// inconnu : l'état de TOUT le parc jusqu'au premier refresh suivant la
/// migration v24. Trois écrans de Facturation en tiraient « votre profil n'a
/// pas le droit », et le chargeur en tirait « ne rien demander » — sur l'écran
/// même où un caissier décide s'il faut encaisser. Un historique vide y fait
/// réencaisser.
///
/// La règle tenue par ces tests : **on ne se tait, et on ne renonce, que sur
/// `missing`** — quand on SAIT que le droit manque. Une lecture tentée à tort
/// coûte un 403, rendu en erreur ; une lecture omise à tort ment.
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
  late _FakeRevalidationCubit revalidationCubit;
  late StreamController<AuthState> authStates;
  late _MockAuthBloc authBloc;

  setUp(() {
    revalidationCubit = _FakeRevalidationCubit();

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

    authStates = StreamController<AuthState>.broadcast();
    authBloc = _MockAuthBloc();
  });

  tearDown(() async {
    await authStates.close();
    await revalidationCubit.close();
  });

  /// Une session dont l'ensemble de permissions peut CHANGER en séance — c'est
  /// la moitié du défaut qu'un état figé ne peut pas éprouver.
  AuthState session(List<String>? permissions) =>
      AuthState(status: AuthStatus.authenticated, permissions: permissions);

  Widget host(List<String>? permissions, Widget child) {
    final initial = session(permissions);
    when(() => authBloc.state).thenReturn(initial);
    whenListen(authBloc, authStates.stream, initialState: initial);

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
              BlocProvider<LedgerRevalidationCubit>.value(
                value: revalidationCubit,
              ),
            ],
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> emitPermissions(
    WidgetTester tester,
    List<String>? permissions,
  ) async {
    authStates.add(session(permissions));
    await tester.pump();
    // Les sections traversent un `AnimatedSwitcher` : sans laisser la
    // transition s'achever, l'ancien enfant est encore à l'arbre et un
    // `findsNothing` échouerait sur une carte en train de disparaître.
    await tester.pumpAndSettle();
  }

  Widget paymentsSection() => FacturationDetailPaymentsSection(
    studentId: 's1',
    academicYearId: 'ay1',
    onCreatePaymentRequested: () {},
    onViewPaymentRequested: (_) {},
  );

  group('section Versements — ensemble inconnu', () {
    testWidgets('ne se tait PAS : « inconnu » n\'accuse personne', (
      tester,
    ) async {
      await tester.pumpWidget(host(null, paymentsSection()));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('payments-withheld')),
        findsNothing,
        reason:
            'la carte « relève de la caisse » accuserait un caissier qui a le '
            'droit, sur l\'écran où il décide s\'il faut encaisser',
      );
    });

    testWidgets('un droit qui ARRIVE en séance rouvre la section', (
      tester,
    ) async {
      // L'abonnement est le cœur du correctif : lu une seule fois, le verdict
      // resterait figé pour la vie de l'écran — rien d'autre ne reconstruit
      // cette section quand les permissions arrivent.
      await tester.pumpWidget(host(secretariat, paymentsSection()));
      await tester.pump();
      expect(find.byKey(const ValueKey('payments-withheld')), findsOneWidget);

      await emitPermissions(tester, caissier);

      expect(find.byKey(const ValueKey('payments-withheld')), findsNothing);
    });

    testWidgets('et un droit RETIRÉ en séance la referme', (tester) async {
      await tester.pumpWidget(host(caissier, paymentsSection()));
      await tester.pump();
      expect(find.byKey(const ValueKey('payments-withheld')), findsNothing);

      await emitPermissions(tester, secretariat);

      expect(find.byKey(const ValueKey('payments-withheld')), findsOneWidget);
    });
  });

  group('section Imputations — ensemble inconnu', () {
    Widget allocationsSection() => const FacturationChargeAllocationsSection(
      chargeId: 'c1',
      paidAmountInCents: 0,
      currency: 'CDF',
    );

    testWidgets('ne se tait pas non plus', (tester) async {
      await tester.pumpWidget(host(null, allocationsSection()));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('charge-allocations-withheld')),
        findsNothing,
      );
    });

    testWidgets('CONTRE-ÉPREUVE : sans le droit, elle se tait toujours', (
      tester,
    ) async {
      await tester.pumpWidget(host(secretariat, allocationsSection()));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('charge-allocations-withheld')),
        findsOneWidget,
      );
    });
  });

  group('chargement des données — ensemble inconnu (M-3)', () {
    Widget loader() => const FacturationDetailDataLoader(
      intent: FacturationDetailIntent.invalid(
        studentId: 's1',
        academicYearId: 'ay1',
      ),
      child: SizedBox.shrink(),
    );

    testWidgets('les versements SONT demandés : on ne renonce que sur '
        '« missing »', (tester) async {
      // Sans quoi le bloc reste `initial`, la section — désormais rouverte —
      // affiche « Aucun versement enregistré », et seul un aller-retour sur la
      // page en sort.
      await tester.pumpWidget(host(null, loader()));
      await tester.pump();

      verify(() => paymentsBloc.add(any())).called(1);
      verify(() => chargesBloc.add(any())).called(1);
    });

    testWidgets('un droit qui ARRIVE après le montage déclenche la lecture de '
        'rattrapage', (tester) async {
      await tester.pumpWidget(host(secretariat, loader()));
      await tester.pump();
      verifyNever(() => paymentsBloc.add(any()));
      clearInteractions(chargesBloc);

      await emitPermissions(tester, caissier);

      final demandes = verify(() => paymentsBloc.add(captureAny())).captured;
      expect(demandes, hasLength(1));
      expect(
        (demandes.single as PaymentsRequested).silent,
        isFalse,
        reason:
            'il n\'y a rien à l\'écran à préserver : le skeleton est honnête',
      );
      verifyNever(() => chargesBloc.add(any()));
    });

    testWidgets('une seule fois : le droit qui rebouge ne relit pas', (
      tester,
    ) async {
      await tester.pumpWidget(host(secretariat, loader()));
      await tester.pump();
      await emitPermissions(tester, caissier);
      clearInteractions(paymentsBloc);

      // Même décision, ensemble différent : un droit qui bouge ailleurs dans le
      // catalogue ne doit pas relancer de lecture.
      await emitPermissions(tester, const [...caissier, 'classroom.read']);

      verifyNever(() => paymentsBloc.add(any()));
    });

    testWidgets('un droit RETIRÉ puis rendu relit vraiment', (tester) async {
      await tester.pumpWidget(host(caissier, loader()));
      await tester.pump();
      verify(() => paymentsBloc.add(any())).called(1);

      await emitPermissions(tester, secretariat);
      await emitPermissions(tester, caissier);

      verify(() => paymentsBloc.add(any())).called(1);
    });
  });

  group('popin de détail d\'un frais — ensemble inconnu', () {
    setUp(() {
      if (getIt.isRegistered<StudentChargesBloc>()) {
        getIt.unregister<StudentChargesBloc>();
      }
      getIt.registerFactory<StudentChargesBloc>(() => chargesBloc);
    });

    tearDown(() => getIt.unregister<StudentChargesBloc>());

    testWidgets('les imputations SONT demandées', (tester) async {
      // La demande ne part qu'ici, à la création de la modale : omise, la popin
      // s'ouvre sur « aucune imputation » sans rien pour l'en sortir hormis la
      // refermer.
      await tester.pumpWidget(
        host(
          null,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showFacturationChargeDetailDialog(
                context,
                intent: const FacturationChargeDetailIntent.invalid(
                  chargeId: 'c1',
                  studentId: 's1',
                  academicYearId: 'ay1',
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pump();

      final demandes = verify(() => chargesBloc.add(captureAny())).captured;
      expect(
        demandes.whereType<StudentChargePaymentAllocationsRequested>(),
        hasLength(1),
      );
    });

    testWidgets('CONTRE-ÉPREUVE : sans le droit, rien n\'est demandé', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          secretariat,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showFacturationChargeDetailDialog(
                context,
                intent: const FacturationChargeDetailIntent.invalid(
                  chargeId: 'c1',
                  studentId: 's1',
                  academicYearId: 'ay1',
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pump();

      verifyNever(
        () => chargesBloc.add(
          any(that: isA<StudentChargePaymentAllocationsRequested>()),
        ),
      );
    });
  });
}
