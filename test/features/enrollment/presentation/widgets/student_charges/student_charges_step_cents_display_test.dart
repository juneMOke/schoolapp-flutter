import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Verrou anti-régression : l'étape Frais (step 6) doit convertir
/// `expectedAmountInCents` en unités monétaires à l'affichage — même contrat
/// que FacturationChargeLine (`cents / 100`) — jamais afficher les cents bruts.
class _MockStudentChargesBloc extends Mock implements StudentChargesBloc {}

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

  setUp(() {
    chargesBloc = _MockStudentChargesBloc();
    whenListen(
      chargesBloc,
      Stream<StudentChargesState>.fromIterable([
        const StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [charge],
        ),
      ]),
      initialState: const StudentChargesState(),
    );
    when(() => chargesBloc.close()).thenAnswer((_) async {});
    getIt.registerFactory<StudentChargesBloc>(() => chargesBloc);
  });

  tearDown(() => getIt.reset());

  testWidgets(
    'charge à 150000 cents → champ et total affichent 1 500, pas 150 000',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: StudentChargesStep(
              studentId: 'stu-1',
              levelId: 'lvl-1',
              enrollmentStatus: EnrollmentStatus.inProgress,
              isEditable: false,
              showInlineSaveButton: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 500'), findsOneWidget);
      expect(find.textContaining('150 000'), findsNothing);
      // Le franc s'écrit « FC » et n'a pas de décimales : la règle
      // d'écriture se décide sur la devise, plus sur la valeur.
      expect(find.textContaining('1 500 FC'), findsOneWidget);
    },
  );

  testWidgets(
    'plus de 2 décimales saisies → rejeté (invalide), pas arrondi en silence',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: StudentChargesStep(
              studentId: 'stu-1',
              levelId: 'lvl-1',
              enrollmentStatus: EnrollmentStatus.inProgress,
              showInlineSaveButton: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1500.567');
      await tester.pumpAndSettle();

      expect(
        find.text('Le champ Montant doit contenir un nombre valide.'),
        findsOneWidget,
      );
    },
  );
}
