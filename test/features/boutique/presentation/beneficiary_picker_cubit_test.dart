import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/beneficiary_picker_cubit.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_list_item.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';

class _MockSearch extends Mock implements SearchLocalEnrollmentsUseCase {}

LocalEnrollmentListItem _item({
  required String studentId,
  required String lastName,
  String firstName = 'Dylan',
  String? surname,
  String? levelId = 'lvl-1',
  String? levelName = '6ème primaire',
  SyncState syncState = SyncState.synced,
}) => LocalEnrollmentListItem(
  enrollmentId: 'enr-$studentId',
  studentId: studentId,
  firstName: firstName,
  lastName: lastName,
  surname: surname,
  dateOfBirth: '2015-01-01',
  gender: OfflineGender.male,
  enrollmentType: EnrollmentType.newEnrollment,
  status: OfflineEnrollmentStatus.completed,
  enrollmentDate: '2026-09-01',
  syncState: syncState,
  schoolLevelId: levelId,
  schoolLevelName: levelName,
);

void main() {
  late _MockSearch search;

  BeneficiaryPickerCubit build() =>
      BeneficiaryPickerCubit(search: search, academicYearId: 'ay-1');

  setUp(() {
    search = _MockSearch();
    when(
      () => search.currentYearEnrolled(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelId: any(named: 'schoolLevelId'),
        schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
      ),
    ).thenAnswer(
      (_) async => Right([
        _item(studentId: 'e1', lastName: 'Ndombo'),
        _item(studentId: 'e2', lastName: 'Mwépu', firstName: 'David'),
      ]),
    );
  });

  test('le mode par défaut est l\'IDENTITÉ, pas le niveau', () {
    // À rebours du socle de recherche, et c'est un cas d'usage différent : en
    // Facturation on traite une classe entière, à la caisse on sert UNE
    // personne, souvent présente.
    expect(build().state.mode, SearchMode.identity);
  });

  blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
    'sous 2 lettres : aucune recherche, aucun appel',
    build: build,
    act: (cubit) => cubit.queryChanged('N'),
    verify: (_) {
      verifyNever(
        () => search.currentYearEnrolled(
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      );
    },
  );

  blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
    'la recherche PLIE les accents',
    // « LOWER() » de SQLite ne les plie pas : le raffinage se fait en Dart, et
    // « Mwepu » doit retrouver « Mwépu ».
    build: build,
    act: (cubit) => cubit.queryChanged('mwepu'),
    verify: (cubit) {
      expect(cubit.state.results.map((c) => c.studentId), ['e2']);
    },
  );

  blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
    'le niveau ne borne PAS la recherche par nom',
    // L'emporter dans l'autre mode masquerait l'élève d'un autre niveau — qui
    // est justement celui qu'on ne retrouve pas.
    build: build,
    act: (cubit) async {
      cubit.switchMode(SearchMode.level);
      await cubit.levelChanged('lvl-9');
      cubit.switchMode(SearchMode.identity);
      await cubit.queryChanged('ndombo');
    },
    verify: (_) {
      verify(
        () => search.currentYearEnrolled(
          academicYearId: 'ay-1',
          schoolLevelId: null,
          schoolLevelGroupId: null,
        ),
      ).called(1);
    },
  );

  blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
    'basculer CONSERVE la saisie de l\'autre mode',
    build: build,
    act: (cubit) async {
      await cubit.queryChanged('ndombo');
      cubit.switchMode(SearchMode.level);
    },
    verify: (cubit) {
      expect(cubit.state.query, 'ndombo');
      // Mais les résultats tombent : ils appartenaient au mode qu'on quitte.
      expect(cubit.state.results, isEmpty);
    },
  );

  group('garde du bénéficiaire', () {
    blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
      'inscription NON synchronisée → visible mais non sélectionnable',
      // La masquer enverrait le guichet chercher un élève qu'il voit dans son
      // registre. Ce qu'on lui doit, c'est la raison et le repli.
      build: build,
      setUp: () {
        when(
          () => search.currentYearEnrolled(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer(
          (_) async => Right([
            _item(
              studentId: 'e3',
              lastName: 'Kabeya',
              syncState: SyncState.pendingSync,
            ),
          ]),
        );
      },
      act: (cubit) => cubit.queryChanged('kabeya'),
      verify: (cubit) {
        final candidate = cubit.state.results.single;
        expect(candidate.enrollmentSynced, isFalse);
        expect(candidate.isSelectable, isFalse);
      },
    );

    blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
      'inscription synchronisée SANS niveau → non sélectionnable',
      // Le serveur ne saurait pas dériver son prix : la vente passerait avec
      // une anomalie et un reçu au bénéficiaire anonyme.
      build: build,
      setUp: () {
        when(
          () => search.currentYearEnrolled(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer(
          (_) async => Right([
            _item(
              studentId: 'e4',
              lastName: 'Sans',
              levelId: null,
              levelName: null,
            ),
          ]),
        );
      },
      act: (cubit) => cubit.queryChanged('sans'),
      verify: (cubit) {
        expect(cubit.state.results.single.isSelectable, isFalse);
      },
    );

    blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
      'inscription synchronisée AVEC niveau → sélectionnable',
      build: build,
      act: (cubit) => cubit.queryChanged('ndombo'),
      verify: (cubit) {
        expect(cubit.state.results.single.isSelectable, isTrue);
      },
    );
  });

  blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
    'les résultats sont bornés',
    // Au-delà, c'est le nom qu'il faut préciser, pas la liste qu'il faut
    // allonger.
    build: build,
    setUp: () {
      when(
        () => search.currentYearEnrolled(
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer(
        (_) async => Right([
          for (var i = 0; i < 30; i++)
            _item(studentId: 'e$i', lastName: 'Ndombo'),
        ]),
      );
    },
    act: (cubit) => cubit.queryChanged('ndombo'),
    verify: (cubit) {
      expect(cubit.state.results, hasLength(BeneficiaryPickerState.maxResults));
    },
  );

  blocTest<BeneficiaryPickerCubit, BeneficiaryPickerState>(
    'un échec de lecture se dit, et ne passe pas pour une liste vide',
    build: build,
    setUp: () {
      when(
        () => search.currentYearEnrolled(
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure('illisible')));
    },
    act: (cubit) => cubit.queryChanged('ndombo'),
    verify: (cubit) {
      expect(cubit.state.status, BeneficiaryPickerStatus.failure);
    },
  );
}
