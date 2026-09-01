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
/// Trois listes déroulantes se remplissaient seules à l'ouverture : un dossier
/// neuf s'ouvrait sur « 2025-2026 · Maternelle · 1ʳᵉ année », trois réponses
/// que personne n'avait données, et qui partaient en base.
///
/// **L'année a depuis été rendue au guichet — mais en PROPOSITION, et elle
/// seule.** Un enfant qui s'inscrit vient presque toujours de l'année qui vient
/// de s'achever, et la redemander à chaque dossier était une corvée sans
/// enjeu. Le cycle et le niveau, eux, restent vides : rien ne permet de les
/// deviner. La différence tient dans le contrat que ces tests gardent : la
/// proposition ne rend pas l'étape « modifiée », donc un enfant jamais
/// scolarisé traverse toujours l'étape sans rien écrire.
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
    String? currentAcademicYearName,
    String? schoolName,
    bool isEditable = true,
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
            currentAcademicYearName: currentAcademicYearName,
            schoolName: schoolName,
            isEditable: isEditable,
          ),
        ),
      ),
    ),
  );

  String prevSchoolText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text;

  List<String?> selectedValues(WidgetTester tester) => tester
      .widgetList<EteeloSelectInput<String>>(
        find.byType(EteeloSelectInput<String>),
      )
      .map((select) => select.value)
      .toList();

  testWidgets('un dossier neuf propose l\'année précédente, et rien d\'autre', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStep(emptyDetail(), currentAcademicYearName: '2026-2027'),
    );
    await tester.pump();

    final values = selectedValues(tester);
    // L'année qui précède celle de l'école — pas celle de l'horloge de la
    // tablette, qui de janvier à août désigne l'année EN COURS.
    expect(values.first, '2025-2026');
    // Cycle et niveau restent vides : rien ne permet de les deviner.
    expect(values.skip(1), everyElement(isNull));
  });

  /// La proposition n'est pas une saisie : l'étape s'ouvre PROPRE. Sans quoi
  /// un enfant jamais scolarisé se verrait réclamer un enregistrement pour
  /// franchir une étape où il n'a rien à déclarer.
  testWidgets('l\'année proposée ne rend pas l\'étape « modifiée »', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStep(emptyDetail(), currentAcademicYearName: '2026-2027'),
    );
    await tester.pump();

    expect(flowBloc.state.stateOf(0).dirty, isFalse);
  });

  /// En consultation, l'écran ne montre que ce que le dossier porte : proposer
  /// une année à un dossier clos qui n'en a pas ferait lire autre chose que la
  /// base.
  testWidgets('en lecture seule, aucune année n\'est proposée', (tester) async {
    await tester.pumpWidget(
      buildStep(
        emptyDetail(),
        currentAcademicYearName: '2026-2027',
        isEditable: false,
      ),
    );
    await tester.pump();

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
      // Le cycle et le niveau du dossier sont retenus tels quels.
      final values = selectedValues(tester);
      expect(values, contains('Primaire'));
      expect(values, contains('P3'));
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

    /// Cocher la case répond à « quelle école avant ? » : c'est la nôtre. Le
    /// guichet n'a donc plus à retaper le nom de sa propre école.
    testWidgets('cocher remplit l\'école précédente avec la nôtre', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildStep(emptyDetail(), schoolName: 'Complexe scolaire Sacré-Cœur'),
      );
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(prevSchoolText(tester), 'Complexe scolaire Sacré-Cœur');
    });

    /// Le geste est réversible dans les deux sens : décocher ne laisse pas
    /// derrière lui un nom d'école que personne n'a saisi, et ne fait pas non
    /// plus disparaître celui qui l'avait été.
    testWidgets('décocher rend le nom qui s\'y trouvait avant', (tester) async {
      await tester.pumpWidget(
        buildStep(emptyDetail(), schoolName: 'Complexe scolaire Sacré-Cœur'),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'EP Kimbanguiste');
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(prevSchoolText(tester), 'Complexe scolaire Sacré-Cœur');

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(prevSchoolText(tester), 'EP Kimbanguiste');
    });

    /// Une case cochée par HYDRATATION (réinscription) n'est pas un geste du
    /// guichet : elle ne doit rien réécrire dans un dossier qui porte déjà son
    /// école précédente.
    testWidgets('la réinscription ne réécrit pas l\'école du dossier', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildStep(
          const EnrollmentSchoolDetail(
            id: 'enr-1',
            status: EnrollmentStatus.inProgress,
            academicYearId: 'ay-2026',
            enrollmentCode: '',
            previousSchoolName: 'EP Kimbanguiste',
            previousAcademicYear: '',
            previousSchoolLevelGroup: '',
            previousSchoolLevel: '',
            schoolLevelGroupId: '',
            schoolLevelId: '',
          ),
          enrollmentType: 'RE_ENROLLMENT',
          schoolName: 'Complexe scolaire Sacré-Cœur',
        ),
      );
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(prevSchoolText(tester), 'EP Kimbanguiste');
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
