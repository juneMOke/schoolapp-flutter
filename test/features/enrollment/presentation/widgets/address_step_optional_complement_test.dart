import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/address_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockEnrollmentOfflineBloc
    extends MockBloc<EnrollmentOfflineEvent, EnrollmentOfflineState>
    implements EnrollmentOfflineBloc {}

/// L'adresse complémentaire (rue, avenue, numéro) est **facultative**.
///
/// Elle était exigée comme les quatre champs géographiques : dans les quartiers
/// où rien n'est numéroté, franchir l'étape imposait d'inventer une ligne. Ce
/// qui reste vrai : la ville, le district, la commune et le quartier sont, eux,
/// toujours obligatoires — sans quoi ce test signerait l'abandon de toute
/// validation plutôt que celui d'un seul champ.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockEnrollmentOfflineBloc offline;

  setUp(() {
    offline = _MockEnrollmentOfflineBloc();
    whenListen(
      offline,
      const Stream<EnrollmentOfflineState>.empty(),
      initialState: const EnrollmentOfflineInitial(),
    );
  });

  // Valeurs prises dans `assets/catalogs/address_geo_catalog.json` : le
  // catalogue re-résout ce qu'il reçoit, et une commune inconnue de lui serait
  // effacée au chargement — l'étape deviendrait invalide pour une raison
  // étrangère à ce que le test prouve.
  StudentDetail student({
    required String address,
    String neighborhood = 'Bitshaku-Tshaku',
  }) => StudentDetail(
    id: 'stu-1',
    firstName: 'Daniel',
    lastName: 'Kabongo',
    surname: 'Mwamba',
    dateOfBirth: '2012-05-04',
    gender: Gender.male,
    birthPlace: 'Kinshasa',
    nationality: 'Congolaise',
    city: 'Kinshasa',
    district: 'Lukunga',
    municipality: 'Barumbu',
    neighborhood: neighborhood,
    address: address,
    schoolLevel: const SchoolLevel(
      id: 'lvl-1',
      name: '6e',
      code: 'L6',
      displayOrder: 1,
      splitIntoClassrooms: false,
    ),
    schoolLevelGroup: const SchoolLevelGroup(
      id: 'grp-1',
      name: 'Secondaire',
      code: 'SEC',
    ),
  );

  Future<void> ouvrir(WidgetTester tester, StudentDetail detail) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<EnrollmentOfflineBloc>.value(
          value: offline,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AddressStep(studentDetail: detail, enrollmentId: 'enr-1'),
            ),
          ),
        ),
      ),
    );
    // Pas de `pumpAndSettle` : tant que le catalogue géographique se charge,
    // la barre de progression indéterminée anime sans fin et la file d'attente
    // ne se vide jamais.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder champ(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is EteeloTextInput && widget.label == label,
    ),
    matching: find.byType(TextField),
  );

  /// « Enregistrer » n'est actif que si l'étape est à la fois modifiée ET
  /// valide : c'est la seule lecture de la validité qu'offre cet écran.
  bool enregistrerActif(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed !=
      null;

  testWidgets('effacer l\'adresse complémentaire laisse l\'étape '
      'enregistrable', (tester) async {
    await ouvrir(tester, student(address: '10, Avenue La source'));

    await tester.enterText(champ('Adresse complémentaire'), '');
    await tester.pump();

    expect(
      enregistrerActif(tester),
      isTrue,
      reason: 'le champ est facultatif : le vider modifie sans invalider',
    );
  });

  testWidgets('le champ ne porte plus d\'étoile d\'obligation', (tester) async {
    await ouvrir(tester, student(address: '10, Avenue La source'));

    final input = tester.widget<EteeloTextInput>(
      find.byWidgetPredicate(
        (widget) =>
            widget is EteeloTextInput &&
            widget.label == 'Adresse complémentaire',
      ),
    );

    expect(input.required, isFalse);
  });

  testWidgets('vidée, elle n\'affiche aucune erreur sous le champ', (
    tester,
  ) async {
    await ouvrir(tester, student(address: '10, Avenue La source'));

    await tester.enterText(champ('Adresse complémentaire'), '');
    await tester.pump();

    // L'écran affiche ses reproches dès qu'il est modifié et invalide : ici il
    // ne l'est plus, donc il n'a rien à reprocher.
    expect(find.textContaining('Adresse complémentaire'), findsOneWidget);
    expect(find.textContaining('obligatoire'), findsNothing);
  });

  /// Le pied du stepper ne lit pas le formulaire : il lit l'état de l'étape
  /// dans le bloc de flux. Or cet état a DEUX sources — ce que l'étape
  /// rapporte, et ce que le dossier sème (`initialState`) à chaque
  /// rechargement, c'est-à-dire après chaque enregistrement. Rendre le champ
  /// facultatif dans le formulaire seul laissait la seconde source exiger
  /// encore un `address` non vide : l'étape se refermait derrière l'usager,
  /// « Continuer » éteint et « Enregistrer » avec lui — plus rien n'étant
  /// modifié, il n'y avait plus d'issue que d'inventer une ligne d'adresse.
  group('la porte du wizard', () {
    EnrollmentDetail dossier({required String address}) => EnrollmentDetail(
      studentDetail: student(address: address),
      parentDetails: const [],
      enrollmentDetail: const EnrollmentSchoolDetail(
        id: 'enr-1',
        status: EnrollmentStatus.inProgress,
        academicYearId: 'ay-2026',
        enrollmentCode: '',
        previousSchoolName: '',
        previousAcademicYear: '',
        previousSchoolLevelGroup: '',
        previousSchoolLevel: '',
        previousRate: null,
        previousRank: null,
        validatedPreviousYear: null,
        schoolLevelGroupId: 'grp-1',
        schoolLevelId: 'lvl-1',
      ),
    );

    StepFormState seme(String address) =>
        AddressStepHandler(
          controller: EnrollmentStepSubmitController(),
        ).initialState(
          HandlerInitialStateContext(detail: dossier(address: address)),
        );

    test('un dossier sans complément sème une étape VALIDE', () {
      expect(seme('').valid, isTrue);
    });

    test('« Continuer » est ouvert sur un dossier sans complément', () {
      final ouvert = EnrollmentStepperStateHelper.canContinueForStep(
        currentStep: 1,
        stepStates: <int, StepFormState>{1: seme('')},
      );

      expect(ouvert, isTrue);
    });

    /// Le quartier, lui, reste exigé : c'est ce qui distingue « un champ
    /// devenu facultatif » de « l'étape ne valide plus rien ».
    test('« Continuer » reste fermé sans quartier', () {
      final sansQuartier =
          AddressStepHandler(
            controller: EnrollmentStepSubmitController(),
          ).initialState(
            HandlerInitialStateContext(
              detail: EnrollmentDetail(
                studentDetail: student(address: '', neighborhood: ''),
                parentDetails: const [],
                enrollmentDetail: dossier(address: '').enrollmentDetail,
              ),
            ),
          );

      expect(
        EnrollmentStepperStateHelper.canContinueForStep(
          currentStep: 1,
          stepStates: <int, StepFormState>{1: sansQuartier},
        ),
        isFalse,
      );
    });
  });
}
