import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_enrollment_duplicates_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/personal_info_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/enrollment_duplicate_guard.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockProbe extends Mock implements ProbeEnrollmentDuplicatesUseCase {}

EnrollmentDuplicateCandidate _found() => const EnrollmentDuplicateCandidate(
  studentId: 'autre',
  enrollmentId: 'autre-e',
  source: EnrollmentDuplicateSource.currentYearDossier,
  level: EnrollmentDuplicateLevel.certain,
  identity: EnrollmentIdentity(
    lastName: 'Mukendi',
    firstName: 'Jean',
    surname: 'Kabeya',
    dateOfBirth: '2015-03-04',
  ),
);

void main() {
  late MockProbe probe;
  late EnrollmentDuplicateGuard guard;
  late AppLocalizations l10n;

  setUpAll(() async {
    // `any(named: 'typed')` a besoin d'une valeur de repli : mocktail ne sait
    // pas fabriquer un `EnrollmentIdentity` tout seul.
    registerFallbackValue(
      const EnrollmentIdentity(lastName: '', firstName: ''),
    );
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  setUp(() {
    probe = MockProbe();
    guard = EnrollmentDuplicateGuard(probe);
  });

  EnrollmentDetail detailWith({
    String lastName = 'Mukendi',
    String firstName = 'Jean',
    String surname = 'Kabeya',
    String dateOfBirth = '2015-03-04',
  }) {
    final empty = EnrollmentDetail.empty();
    return EnrollmentDetail(
      studentDetail: StudentDetail(
        id: 'self',
        firstName: firstName,
        lastName: lastName,
        surname: surname,
        gender: Gender.male,
        dateOfBirth: dateOfBirth,
        birthPlace: 'Kinshasa',
        nationality: 'Congolaise',
        city: '',
        district: '',
        municipality: '',
        neighborhood: '',
        address: '',
        schoolLevel: empty.studentDetail.schoolLevel,
        schoolLevelGroup: empty.studentDetail.schoolLevelGroup,
      ),
      parentDetails: empty.parentDetails,
      enrollmentDetail: const EnrollmentSchoolDetail(
        id: 'self-e',
        status: EnrollmentStatus.inProgress,
        academicYearId: 'ay-2026',
        enrollmentCode: '',
        previousSchoolName: '',
        previousAcademicYear: '',
        previousSchoolLevelGroup: '',
        previousSchoolLevel: '',
        schoolLevelGroupId: '',
        schoolLevelId: '',
      ),
    );
  }

  void givenFound(List<EnrollmentDuplicateCandidate> candidates) {
    when(
      () => probe(
        typed: any(named: 'typed'),
        studentId: any(named: 'studentId'),
        enrollmentId: any(named: 'enrollmentId'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => Right(candidates));
  }

  /// Monte un écran d'où la garde est interrogée, et retient sa réponse.
  Future<void> pumpAndAsk(
    WidgetTester tester, {
    required EnrollmentDetail detail,
    required EnrollmentDetailPolicy policy,
    required void Function(bool) onAnswer,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final allowed = await guard.allowContinue(
                  context: context,
                  detail: detail,
                  detailPolicy: policy,
                );
                onAnswer(allowed);
              },
              child: const Text('continuer'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('continuer'));
    await tester.pumpAndSettle();
  }

  group('appliesTo — la sonde ne tourne qu\'en Première inscription', () {
    test('dossier NEW éditable : elle s\'applique', () {
      expect(guard.appliesTo(const NewFirstRegistrationDetailPolicy()), isTrue);
    });

    test('pré-inscription : jamais', () {
      expect(guard.appliesTo(const PreRegistrationDetailPolicy()), isFalse);
    });

    test('réinscription : jamais', () {
      expect(guard.appliesTo(const ReRegistrationDetailPolicy()), isFalse);
    });

    test('consultation lecture seule : jamais', () {
      // Rien à corriger : avertir n'offrirait aucune suite.
      expect(guard.appliesTo(const LocalConsultationDetailPolicy()), isFalse);
    });

    test('reprise d\'un brouillon NEW : elle s\'applique', () {
      expect(
        guard.appliesTo(
          const LocalDraftResumeDetailPolicy(enrollmentType: 'NEW_ENROLLMENT'),
        ),
        isTrue,
      );
    });

    test('reprise d\'un brouillon RE : jamais', () {
      expect(
        guard.appliesTo(
          const LocalDraftResumeDetailPolicy(enrollmentType: 'RE_ENROLLMENT'),
        ),
        isFalse,
      );
    });

    // Le périmètre réel compte TROIS politiques live, pas deux : la réédition
    // d'un dossier soldé rouvre l'étape Identité, et son type retombe sur NEW
    // faute de mieux. On l'épingle ici pour que le périmètre soit une décision
    // lisible plutôt qu'un effet de bord du défaut `draftEnrollmentType`.
    test('réédition d\'un dossier NEW soldé : elle s\'applique', () {
      expect(
        guard.appliesTo(
          const CompletedReeditionDetailPolicy(
            enrollmentType: 'NEW_ENROLLMENT',
          ),
        ),
        isTrue,
      );
    });

    test('réédition sans type connu : elle s\'applique (défaut NEW)', () {
      expect(guard.appliesTo(const CompletedReeditionDetailPolicy()), isTrue);
    });

    test('réédition d\'un dossier RE soldé : jamais', () {
      expect(
        guard.appliesTo(
          const CompletedReeditionDetailPolicy(enrollmentType: 'RE_ENROLLMENT'),
        ),
        isFalse,
      );
    });
  });

  testWidgets('hors périmètre : aucune lecture n\'est même payée', (
    tester,
  ) async {
    givenFound([_found()]);
    bool? allowed;

    await pumpAndAsk(
      tester,
      detail: detailWith(),
      policy: const ReRegistrationDetailPolicy(),
      onAnswer: (value) => allowed = value,
    );

    expect(allowed, isTrue);
    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsNothing);
    verifyNever(
      () => probe(
        typed: any(named: 'typed'),
        studentId: any(named: 'studentId'),
        enrollmentId: any(named: 'enrollmentId'),
        academicYearId: any(named: 'academicYearId'),
      ),
    );
  });

  testWidgets('rien trouvé : on passe, sans rien montrer', (tester) async {
    givenFound(const []);
    bool? allowed;

    await pumpAndAsk(
      tester,
      detail: detailWith(),
      policy: const NewFirstRegistrationDetailPolicy(),
      onAnswer: (value) => allowed = value,
    );

    expect(allowed, isTrue);
    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsNothing);
  });

  testWidgets('lecture en échec : on passe, la sonde n\'a rien à dire', (
    tester,
  ) async {
    when(
      () => probe(
        typed: any(named: 'typed'),
        studentId: any(named: 'studentId'),
        enrollmentId: any(named: 'enrollmentId'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('base fermée')));
    bool? allowed;

    await pumpAndAsk(
      tester,
      detail: detailWith(),
      policy: const NewFirstRegistrationDetailPolicy(),
      onAnswer: (value) => allowed = value,
    );

    expect(allowed, isTrue);
    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsNothing);
  });

  testWidgets('les ids du brouillon et l\'année partent à la sonde', (
    tester,
  ) async {
    givenFound(const []);

    await pumpAndAsk(
      tester,
      detail: detailWith(),
      policy: const NewFirstRegistrationDetailPolicy(),
      onAnswer: (_) {},
    );

    final captured = verify(
      () => probe(
        typed: captureAny(named: 'typed'),
        studentId: captureAny(named: 'studentId'),
        enrollmentId: captureAny(named: 'enrollmentId'),
        academicYearId: captureAny(named: 'academicYearId'),
      ),
    ).captured;

    expect(captured[0], isA<EnrollmentIdentity>());
    expect((captured[0] as EnrollmentIdentity).lastName, 'Mukendi');
    expect(captured[1], 'self');
    expect(captured[2], 'self-e');
    expect(captured[3], 'ay-2026');
  });

  testWidgets('trouvé, puis « Continuer quand même » : on passe', (
    tester,
  ) async {
    givenFound([_found()]);
    bool? allowed;

    await pumpAndAsk(
      tester,
      detail: detailWith(),
      policy: const NewFirstRegistrationDetailPolicy(),
      onAnswer: (value) => allowed = value,
    );

    expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsOneWidget);
    await tester.tap(find.text(l10n.enrollmentDuplicateContinueAction));
    await tester.pumpAndSettle();

    expect(allowed, isTrue);
  });

  testWidgets('trouvé, puis « Corriger » : on reste', (tester) async {
    givenFound([_found()]);
    bool? allowed;

    await pumpAndAsk(
      tester,
      detail: detailWith(),
      policy: const NewFirstRegistrationDetailPolicy(),
      onAnswer: (value) => allowed = value,
    );

    await tester.tap(find.text(l10n.enrollmentDuplicateFixAction));
    await tester.pumpAndSettle();

    expect(allowed, isFalse);
  });

  /// Le maillon que rien d'autre ne tient : sans lui, retirer l'appel à la
  /// sonde dans le handler laisse toute la suite verte — la sonde existe,
  /// fonctionne, et n'est jamais posée.
  group('câblage — l\'étape Identité pose bien la question', () {
    Future<void> pumpAndAskHandler(
      WidgetTester tester, {
      required EnrollmentDetailPolicy policy,
      required void Function(bool) onAnswer,
    }) async {
      final handler = PersonalInfoStepHandler(
        controller: EnrollmentStepSubmitController(),
        duplicateGuard: guard,
      );
      final detail = detailWith();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final allowed = await handler.confirmBeforeContinue(
                    HandlerConfirmContext(
                      context: context,
                      detail: detail,
                      intent:
                          const EnrollmentDetailIntent.newFirstRegistration(),
                      detailPolicy: policy,
                      l10n: l10n,
                    ),
                  );
                  onAnswer(allowed);
                },
                child: const Text('continuer'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('continuer'));
      await tester.pumpAndSettle();
    }

    testWidgets('un doublon trouvé remonte jusqu\'à la popin', (tester) async {
      givenFound([_found()]);
      bool? allowed;

      await pumpAndAskHandler(
        tester,
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (value) => allowed = value,
      );

      expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsOneWidget);
      await tester.tap(find.text(l10n.enrollmentDuplicateFixAction));
      await tester.pumpAndSettle();

      expect(allowed, isFalse);
    });

    testWidgets('rien trouvé : le handler laisse franchir', (tester) async {
      givenFound(const []);
      bool? allowed;

      await pumpAndAskHandler(
        tester,
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (value) => allowed = value,
      );

      expect(allowed, isTrue);
      verify(
        () => probe(
          typed: any(named: 'typed'),
          studentId: any(named: 'studentId'),
          enrollmentId: any(named: 'enrollmentId'),
          academicYearId: any(named: 'academicYearId'),
        ),
      ).called(1);
    });
  });

  // Le wizard se monte bien plus souvent qu'il n'interroge : consultation,
  // réédition, réinscription. Résoudre la sonde au montage couplait chacun de
  // ces parcours au conteneur global — et faisait tomber six suites qui montent
  // l'écran par injection explicite, sans `getIt`. Trouvé en revue DUP-5, et
  // seulement en suite complète : chaque fichier de la sonde passait, isolé.
  group('résolution différée — le conteneur attend son tour', () {
    test('hors périmètre : la sonde n\'est même pas résolue', () async {
      var resolutions = 0;
      final lazyGuard = EnrollmentDuplicateGuard.lazy(() {
        resolutions++;
        return probe;
      });

      // Un parcours en lecture seule : ce que fait le wizard la plupart du temps.
      expect(
        lazyGuard.appliesTo(const LocalConsultationDetailPolicy()),
        isFalse,
      );
      expect(resolutions, 0);
    });

    testWidgets('dans le périmètre : résolue une fois, puis mémorisée', (
      tester,
    ) async {
      givenFound(const []);
      var resolutions = 0;
      guard = EnrollmentDuplicateGuard.lazy(() {
        resolutions++;
        return probe;
      });

      await pumpAndAsk(
        tester,
        detail: detailWith(),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );
      await pumpAndAsk(
        tester,
        detail: detailWith(lastName: 'Ilunga'),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );

      // Deux confrontations, une seule visite au conteneur.
      expect(resolutions, 1);
    });
  });

  group('mémoire de session', () {
    testWidgets('ce qu\'on a assumé n\'est pas redemandé', (tester) async {
      givenFound([_found()]);
      final detail = detailWith();

      await pumpAndAsk(
        tester,
        detail: detail,
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );
      await tester.tap(find.text(l10n.enrollmentDuplicateContinueAction));
      await tester.pumpAndSettle();

      // Deuxième passage sur la même identité : ni lecture, ni popin.
      bool? allowed;
      await pumpAndAsk(
        tester,
        detail: detail,
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (value) => allowed = value,
      );

      expect(allowed, isTrue);
      expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsNothing);
      verify(
        () => probe(
          typed: any(named: 'typed'),
          studentId: any(named: 'studentId'),
          enrollmentId: any(named: 'enrollmentId'),
          academicYearId: any(named: 'academicYearId'),
        ),
      ).called(1);
    });

    testWidgets('« Corriger » ne vaut PAS acquiescement', (tester) async {
      givenFound([_found()]);
      final detail = detailWith();

      await pumpAndAsk(
        tester,
        detail: detail,
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );
      await tester.tap(find.text(l10n.enrollmentDuplicateFixAction));
      await tester.pumpAndSettle();

      // Il ressort sans avoir rien changé : le même avertissement revient, ce
      // qui est juste — rien n'a changé.
      await pumpAndAsk(
        tester,
        detail: detail,
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );

      expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsOneWidget);
    });

    testWidgets('la mémoire ignore casse et accents', (tester) async {
      givenFound([_found()]);

      await pumpAndAsk(
        tester,
        detail: detailWith(lastName: 'Mukendi'),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );
      await tester.tap(find.text(l10n.enrollmentDuplicateContinueAction));
      await tester.pumpAndSettle();

      // Corriger « Mukendi » en « MUKÉNDI » ne change pas l'identité : ce
      // serait redemander ce qu'on vient d'écarter.
      bool? allowed;
      await pumpAndAsk(
        tester,
        detail: detailWith(lastName: 'MUKÉNDI'),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (value) => allowed = value,
      );

      expect(allowed, isTrue);
      expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsNothing);
    });

    testWidgets('une identité VRAIMENT changée est reconfrontée', (
      tester,
    ) async {
      givenFound([_found()]);

      await pumpAndAsk(
        tester,
        detail: detailWith(firstName: 'Jean'),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );
      await tester.tap(find.text(l10n.enrollmentDuplicateContinueAction));
      await tester.pumpAndSettle();

      await pumpAndAsk(
        tester,
        detail: detailWith(firstName: 'Pierre'),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );

      expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsOneWidget);
    });

    testWidgets('une date de naissance changée est reconfrontée', (
      tester,
    ) async {
      givenFound([_found()]);

      await pumpAndAsk(
        tester,
        detail: detailWith(dateOfBirth: '2015-03-04'),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );
      await tester.tap(find.text(l10n.enrollmentDuplicateContinueAction));
      await tester.pumpAndSettle();

      await pumpAndAsk(
        tester,
        detail: detailWith(dateOfBirth: '2014-03-04'),
        policy: const NewFirstRegistrationDetailPolicy(),
        onAnswer: (_) {},
      );

      expect(find.text(l10n.enrollmentDuplicateDialogTitle), findsOneWidget);
    });
  });
}
