import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step_body.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockStudentChargesBloc extends Mock implements StudentChargesBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Exerce la **seule ligne** qui relie la permission au blocage de l'étape
/// Frais : la lecture de `finance.grid.read` dans `didChangeDependencies`.
///
/// Le reste de la chaîne est couvert en passant les drapeaux explicitement au
/// corps et au contrôleur — ce qui laisse cette ligne libre de lire la mauvaise
/// permission, ou de n'être jamais appelée, sans qu'aucun test ne rougisse.
void main() {
  setUpAll(() {
    registerFallbackValue(
      const StudentChargesRequested(
        studentId: 'x',
        levelId: 'x',
        academicYearId: 'x',
      ),
    );
  });

  late _MockStudentChargesBloc chargesBloc;

  setUp(() {
    chargesBloc = _MockStudentChargesBloc();
    // Créances vides et grille présente sur l'appareil : la seule variable qui
    // reste est le droit du compte courant.
    whenListen(
      chargesBloc,
      Stream<StudentChargesState>.fromIterable([
        const StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [],
        ),
      ]),
      initialState: const StudentChargesState(),
    );
    when(() => chargesBloc.close()).thenAnswer((_) async {});
    getIt.registerFactory<StudentChargesBloc>(() => chargesBloc);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, List<String>? permissions) async {
    final authBloc = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => authBloc.state).thenReturn(state);
    whenListen(authBloc, Stream<AuthState>.value(state), initialState: state);
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const Scaffold(
            body: StudentChargesStep(
              studentId: 'stu-1',
              levelId: 'lvl-1',
              enrollmentStatus: EnrollmentStatus.inProgress,
              isEditable: false,
              showInlineSaveButton: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans finance.grid.read : le motif du droit est affiché', (
    tester,
  ) async {
    await pump(tester, const ['enrollment.read', 'enrollment.write']);

    expect(find.byType(StudentChargesEmptyState), findsNothing);
    expect(find.textContaining('grille tarifaire'), findsOneWidget);
  });

  testWidgets('avec finance.grid.read : « aucune charge » légitime', (
    tester,
  ) async {
    await pump(tester, const ['enrollment.read', 'finance.grid.read']);

    expect(find.byType(StudentChargesEmptyState), findsOneWidget);
    expect(find.textContaining('grille tarifaire'), findsNothing);
  });

  // Fail-closed : un ensemble inconnu ne permet pas d'affirmer que le compte a
  // le droit, donc il ne permet pas d'annoncer un montant.
  testWidgets('droits inconnus : traité comme le droit manquant', (
    tester,
  ) async {
    await pump(tester, null);

    expect(find.byType(StudentChargesEmptyState), findsNothing);
    expect(find.textContaining('grille tarifaire'), findsOneWidget);
  });

  // La lecture est ponctuelle (`PermissionGate.allows` ne s'abonne à rien) et la
  // valeur vit hors `build`, puisque la validité de l'étape en dépend. Sans
  // abonnement explicite au changement de droits, le verdict restait figé à
  // celui du montage : un refresh en arrière-plan accordait `finance.grid.read`
  // sans que l'étape s'en aperçoive.
  testWidgets('un droit accordé en cours de session débloque l\'étape', (
    tester,
  ) async {
    final emissions = StreamController<AuthState>.broadcast();
    addTearDown(emissions.close);

    var current = const AuthState(
      status: AuthStatus.authenticated,
      permissions: ['enrollment.read'],
    );
    final authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenAnswer((_) => current);
    whenListen(authBloc, emissions.stream, initialState: current);
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const Scaffold(
            body: StudentChargesStep(
              studentId: 'stu-1',
              levelId: 'lvl-1',
              enrollmentStatus: EnrollmentStatus.inProgress,
              isEditable: false,
              showInlineSaveButton: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('grille tarifaire'), findsOneWidget);

    current = const AuthState(
      status: AuthStatus.authenticated,
      permissions: ['enrollment.read', 'finance.grid.read'],
    );
    emissions.add(current);
    await tester.pumpAndSettle();

    expect(find.textContaining('grille tarifaire'), findsNothing);
    expect(find.byType(StudentChargesEmptyState), findsOneWidget);
  });

  // Le piège que ce test existe pour attraper : lire la mauvaise permission.
  // `finance.charge.read` ouvre la fiche de facturation, pas la grille.
  testWidgets('une permission finance voisine ne débloque pas l\'étape', (
    tester,
  ) async {
    await pump(tester, const ['finance.charge.read', 'finance.payment.read']);

    expect(find.textContaining('grille tarifaire'), findsOneWidget);
  });

  // M-7 — le rebuild ne doit pas dépendre d'une COÏNCIDENCE.
  //
  // `_syncTariffsWithheld` s'en remettait à `_recomputeFormState` pour appeler
  // `setState`, or celui-ci ne reconstruit que si la VALIDITÉ change. Et le
  // droit sur la grille n'entre dans la validité que par
  // `blocked = (tariffsWithheld || feeGridUnavailable) && charges.isEmpty` :
  // dès que des créances sont chargées — le cas normal — le verdict de droit
  // change sans que rien ne reconstruise.
  //
  // ⚠️ Ce que ce test mesure est le PROP reçu par le corps, pas un pixel. Avec
  // des créances à l'écran, le corps affiche la liste quel que soit le droit :
  // rien ne bouge visuellement aujourd'hui, et c'est précisément pourquoi le
  // défaut est passé. Ce qui est en jeu est le contrat — le corps reçoit
  // toujours le droit courant — et non son rendu du moment. Le jour où ce
  // rendu dépendra du droit avec une liste non vide, la panne serait visible
  // et muette.
  group('changement de droit avec des créances à l\'écran', () {
    const charge = StudentCharge(
      id: 'c1',
      studentId: 'stu-1',
      academicYearId: 'y1',
      schoolLevelId: 'lvl-1',
      schoolLevelGroupId: 'grp-1',
      feeTariffId: 't1',
      feeCode: 'TUITION',
      label: 'Frais de scolarité',
      expectedAmountInCents: 150000,
      amountPaidInCents: 0,
      currency: 'CDF',
      status: StudentChargeStatus.due,
    );

    bool bodyWithheld(WidgetTester tester) => tester
        .widget<StudentChargesStepBody>(find.byType(StudentChargesStepBody))
        .tariffsWithheld;

    testWidgets('le droit RETIRÉ en séance atteint le corps', (tester) async {
      // Créances présentes : la validité vaut `true` avec ou sans le droit,
      // donc `_recomputeFormState` ne signale aucun changement et ne
      // reconstruit pas. Sans rebuild explicite, le corps garde le droit
      // observé au montage jusqu'à un rebuild venu d'ailleurs.
      final chargesLoaded = _MockStudentChargesBloc();
      whenListen(
        chargesLoaded,
        Stream<StudentChargesState>.fromIterable([
          const StudentChargesState(
            status: StudentChargesStatus.success,
            studentCharges: [charge],
          ),
        ]),
        initialState: const StudentChargesState(),
      );
      when(() => chargesLoaded.close()).thenAnswer((_) async {});
      await getIt.reset();
      getIt.registerFactory<StudentChargesBloc>(() => chargesLoaded);

      final emissions = StreamController<AuthState>.broadcast();
      addTearDown(emissions.close);
      var current = const AuthState(
        status: AuthStatus.authenticated,
        permissions: ['enrollment.read', 'finance.grid.read'],
      );
      final authBloc = _MockAuthBloc();
      when(() => authBloc.state).thenAnswer((_) => current);
      whenListen(authBloc, emissions.stream, initialState: current);
      addTearDown(authBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const Scaffold(
              body: StudentChargesStep(
                studentId: 'stu-1',
                levelId: 'lvl-1',
                enrollmentStatus: EnrollmentStatus.inProgress,
                isEditable: false,
                showInlineSaveButton: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(bodyWithheld(tester), isFalse, reason: 'droit détenu au montage');

      current = const AuthState(
        status: AuthStatus.authenticated,
        permissions: ['enrollment.read'],
      );
      emissions.add(current);
      await tester.pumpAndSettle();

      expect(
        bodyWithheld(tester),
        isTrue,
        reason:
            'le corps doit voir le droit courant, sans attendre qu\'un autre '
            'changement d\'état le reconstruise par hasard',
      );
    });
  });
}
