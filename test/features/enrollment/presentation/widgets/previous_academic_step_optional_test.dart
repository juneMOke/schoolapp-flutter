import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/previous_academic_info_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockDraftBloc extends Mock implements EnrollmentOfflineBloc {}

/// Étape « Scolarité antérieure » — **le bloc est facultatif en entier**.
///
/// Ce qui se joue ici n'est pas la validation d'un formulaire mais la
/// disparition d'une fabrication. Trois listes déroulantes se remplissaient
/// seules à l'ouverture (`_resolveYear` retombait sur `options.first`, le
/// catalogue sur `firstCycle` puis `firstLevelForCycle`) : un dossier neuf
/// s'ouvrait sur « 2025-2026 · Maternelle · 1ʳᵉ année », trois réponses que
/// personne n'avait données. Tant que les champs étaient obligatoires, cela
/// passait pour une commodité de saisie ; du jour où ils deviennent
/// facultatifs, c'est de l'invention pure — et elle part en base.
void main() {
  late _MockDraftBloc draftBloc;
  late EnrollmentStepperFlowBloc flowBloc;

  setUpAll(() {
    registerFallbackValue(
      const SaveDraftPreviousAcademicRequested(enrollmentId: 'x'),
    );
  });

  setUp(() {
    draftBloc = _MockDraftBloc();
    flowBloc = EnrollmentStepperFlowBloc(
      totalSteps: 7,
      initialStepStates: const {0: StepFormState()},
    );
    when(
      () => draftBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
    when(() => draftBloc.state).thenReturn(const EnrollmentOfflineInitial());
  });

  tearDown(() async {
    await flowBloc.close();
  });

  /// Dossier neuf : rien de saisi, comme au premier affichage de l'étape.
  EnrollmentSchoolDetail emptyDetail() => const EnrollmentSchoolDetail(
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
    schoolLevelGroupId: '',
    schoolLevelId: '',
  );

  Widget buildStep(
    EnrollmentSchoolDetail detail, {
    EnrollmentStepSubmitController? controller,
    String enrollmentType = 'NEW_ENROLLMENT',
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentOfflineBloc>.value(value: draftBloc),
        BlocProvider<EnrollmentStepperFlowBloc>.value(value: flowBloc),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: PreviousAcademicInfoStep(
            enrollmentDetail: detail,
            enrollmentId: 'enr-1',
            enrollmentType: enrollmentType,
            showInlineSaveButton: false,
            flowStepIndex: 0,
            stepController: controller,
          ),
        ),
      ),
    ),
  );

  List<String?> selectedValues(WidgetTester tester) => tester
      .widgetList<EteeloSelectInput<String>>(
        find.byType(EteeloSelectInput<String>),
      )
      .map((select) => select.value)
      .toList();

  testWidgets('un dossier neuf ouvre l\'étape sur trois listes VIDES', (
    tester,
  ) async {
    await tester.pumpWidget(buildStep(emptyDetail()));
    await tester.pump();

    // Année, cycle, niveau : aucune valeur pré-choisie.
    expect(selectedValues(tester), everyElement(isNull));
  });

  testWidgets('l\'étape est franchissable sans rien saisir', (tester) async {
    await tester.pumpWidget(buildStep(emptyDetail()));
    await tester.pump();

    final reported = flowBloc.state.stateOf(0);
    expect(
      reported.valid,
      isTrue,
      reason: 'un enfant jamais scolarisé doit pouvoir traverser l\'étape',
    );
  });

  testWidgets(
    'une valeur déjà portée par le dossier est RECONNUE, pas remplacée',
    (tester) async {
      await tester.pumpWidget(
        buildStep(
          const EnrollmentSchoolDetail(
            id: 'enr-1',
            status: EnrollmentStatus.inProgress,
            academicYearId: 'ay-2026',
            enrollmentCode: '',
            previousSchoolName: 'École Saint-Joseph',
            previousAcademicYear: '',
            previousSchoolLevelGroup: 'Primaire',
            previousSchoolLevel: 'P3',
            previousRate: 72.5,
            previousRank: 4,
            validatedPreviousYear: true,
            schoolLevelGroupId: '',
            schoolLevelId: '',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('École Saint-Joseph'), findsOneWidget);
      // Le cycle et le niveau du dossier sont retenus tels quels — et l'année,
      // que le dossier ne porte pas, reste vide plutôt que d'être inventée.
      final values = selectedValues(tester);
      expect(values, contains('Primaire'));
      expect(values, contains('P3'));
      expect(values.first, isNull);
    },
  );

  testWidgets('une moyenne hors bornes est refusée, une moyenne vide non', (
    tester,
  ) async {
    final controller = EnrollmentStepSubmitController();
    await tester.pumpWidget(buildStep(emptyDetail(), controller: controller));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    // Vide : rien à signaler, l'étape reste valide.
    expect(flowBloc.state.stateOf(0).valid, isTrue);

    // 850 % est plus sûrement une faute de frappe qu'un résultat.
    await tester.enterText(find.byType(TextField).at(1), '850');
    await tester.pump();

    expect(flowBloc.state.stateOf(0).valid, isFalse);

    controller.submitForm();
    await tester.pump();

    expect(find.text(l10n.averageOutOfRangeError), findsWidgets);
    // Rien n'est parti au brouillon : la saisie est refusée avant l'écriture.
    verifyNever(() => draftBloc.add(any()));
  });

  group('« ancien élève » — le nouveau / ancien du formulaire', () {
    /// Le drapeau est DÉLIBÉRÉMENT distinct du type d'inscription : une école
    /// qui démarre sur l'application inscrit tous ses anciens élèves en
    /// NEW_ENROLLMENT, faute de dossier N-1. C'est précisément ce que cette
    /// case sert à dire, et elle doit donc être cochable là.
    testWidgets('en première inscription : décochée et modifiable', (
      tester,
    ) async {
      final controller = EnrollmentStepSubmitController();
      await tester.pumpWidget(buildStep(emptyDetail(), controller: controller));
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

      controller.submitForm();
      await tester.pump();

      final saved =
          verify(() => draftBloc.add(captureAny())).captured.single
              as SaveDraftPreviousAcademicRequested;
      expect(saved.formerStudent, isTrue);
    });

    /// En réinscription le fait est ACQUIS : le dossier vient d'une inscription
    /// de l'année précédente dans cette école. Verrouillée, mais en lecture
    /// seule pleine couleur — pas grisée, la valeur reste une information.
    testWidgets('en réinscription : cochée et verrouillée', (tester) async {
      await tester.pumpWidget(
        buildStep(emptyDetail(), enrollmentType: 'RE_ENROLLMENT'),
      );
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

      // Un tap ne la décoche pas.
      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    /// Une préinscription est un FUTUR élève, pas un ancien : même repli que
    /// `EnrollmentType.formerStudentOrDefault` côté serveur, qui ne dérive
    /// `true` que de RE_ENROLLMENT.
    testWidgets('en préinscription : décochée et modifiable', (tester) async {
      await tester.pumpWidget(
        buildStep(emptyDetail(), enrollmentType: 'PRE_ENROLLMENT'),
      );
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('la valeur du dossier est relue telle quelle', (tester) async {
      await tester.pumpWidget(
        buildStep(
          const EnrollmentSchoolDetail(
            id: 'enr-1',
            status: EnrollmentStatus.inProgress,
            academicYearId: 'ay-2026',
            enrollmentCode: '',
            previousSchoolName: '',
            previousAcademicYear: '',
            previousSchoolLevelGroup: '',
            previousSchoolLevel: '',
            formerStudent: true,
            schoolLevelGroupId: '',
            schoolLevelId: '',
          ),
        ),
      );
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });
  });

  /// **Un verdict enregistré ne se perd pas en corrigeant autre chose.**
  ///
  /// Depuis que la moyenne est facultative, un dossier peut porter « Année
  /// validée = Oui » sans moyenne. La déduction automatique était rejouée à
  /// chaque frappe, dans n'importe quel champ : corriger une faute dans le nom
  /// de l'école suffisait à effacer le verdict — et, dans la foulée, à couper
  /// le calcul automatique de la classe cible, qui s'arrête sur `null`.
  testWidgets('corriger un autre champ n\'efface pas un verdict enregistré', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStep(
        const EnrollmentSchoolDetail(
          id: 'enr-1',
          status: EnrollmentStatus.inProgress,
          academicYearId: 'ay-2026',
          enrollmentCode: '',
          previousSchoolName: 'École Saint-Joseph',
          previousAcademicYear: '',
          previousSchoolLevelGroup: '',
          previousSchoolLevel: '',
          previousRate: null,
          previousRank: null,
          validatedPreviousYear: true,
          schoolLevelGroupId: '',
          schoolLevelId: '',
        ),
      ),
    );
    await tester.pump();

    // Le champ 0 est l'école : rien à voir avec la moyenne.
    await tester.enterText(
      find.byType(TextField).at(0),
      'École Saint-Joseph (corrigé)',
    );
    await tester.pump();

    expect(
      tester
          .widget<SegmentedButton<bool?>>(find.byType(SegmentedButton<bool?>))
          .selected,
      {true},
      reason: 'le verdict enregistré survit à la correction d\'un autre champ',
    );
  });

  /// Sans moyenne, aucune déduction. Le sélecteur d'année validée suit la
  /// moyenne tant que personne ne l'a touché — mais une moyenne effacée doit
  /// emporter ce qu'elle avait déduit, sinon le dossier garderait un verdict
  /// dont la justification vient de disparaître.
  testWidgets('effacer la moyenne remet l\'année à « non renseignée »', (
    tester,
  ) async {
    await tester.pumpWidget(buildStep(emptyDetail()));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final rateField = find.byType(TextField).at(1);

    await tester.enterText(rateField, '72');
    await tester.pump();
    expect(
      tester
          .widget<SegmentedButton<bool?>>(find.byType(SegmentedButton<bool?>))
          .selected,
      {true},
    );

    await tester.enterText(rateField, '');
    await tester.pump();
    expect(
      tester
          .widget<SegmentedButton<bool?>>(find.byType(SegmentedButton<bool?>))
          .selected,
      {null},
      reason: 'le verdict déduit disparaît avec ce qui le justifiait',
    );

    // Et le troisième segment existe bien, nommé.
    expect(find.text(l10n.yearValidationUnknown), findsOneWidget);
  });
}
