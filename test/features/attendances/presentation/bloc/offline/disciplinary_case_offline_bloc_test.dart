import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/create_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_offline_disciplinary_cases_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/update_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';

class MockCreateDisciplinaryCaseOfflineUseCase extends Mock
    implements CreateDisciplinaryCaseOfflineUseCase {}

class MockUpdateDisciplinaryCaseOfflineUseCase extends Mock
    implements UpdateDisciplinaryCaseOfflineUseCase {}

class MockGetOfflineDisciplinaryCasesUseCase extends Mock
    implements GetOfflineDisciplinaryCasesUseCase {}

void main() {
  late MockCreateDisciplinaryCaseOfflineUseCase mockCreate;
  late MockUpdateDisciplinaryCaseOfflineUseCase mockUpdate;
  late MockGetOfflineDisciplinaryCasesUseCase mockGet;

  final tCase = OfflineDisciplinaryCase(
    id: 'case-1',
    studentId: 'stu-1',
    studentFirstName: 'John',
    studentLastName: 'Doe',
    studentGender: StudentGender.male,
    academicYearId: 'ay-1',
    disciplinaryCaseDate: DateTime(2026, 3, 12),
    title: 'Bagarre',
    content: 'Altercation dans la cour.',
    category: DisciplinaryCategory.fighting,
    severity: DisciplinarySeverity.serious,
    status: DisciplinaryStatus.open,
    updatedAt: 1710000000000,
  );

  setUpAll(() {
    registerFallbackValue(StudentGender.male);
    registerFallbackValue(DisciplinaryCategory.fighting);
    registerFallbackValue(DisciplinarySeverity.serious);
    registerFallbackValue(DisciplinarySanction.oralWarning);
    registerFallbackValue(DisciplinaryStatus.open);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    mockCreate = MockCreateDisciplinaryCaseOfflineUseCase();
    mockUpdate = MockUpdateDisciplinaryCaseOfflineUseCase();
    mockGet = MockGetOfflineDisciplinaryCasesUseCase();
  });

  DisciplinaryCaseOfflineBloc buildBloc() => DisciplinaryCaseOfflineBloc(
    createCase: mockCreate,
    updateCase: mockUpdate,
    getCases: mockGet,
  );

  void stubGet(Either<Failure, List<OfflineDisciplinaryCase>> answer) {
    when(
      () => mockGet(
        studentId: any(named: 'studentId'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => answer);
  }

  void stubCreate(Either<Failure, OfflineDisciplinaryCase> answer) {
    when(
      () => mockCreate(
        studentId: any(named: 'studentId'),
        studentFirstName: any(named: 'studentFirstName'),
        studentLastName: any(named: 'studentLastName'),
        studentMiddleName: any(named: 'studentMiddleName'),
        studentGender: any(named: 'studentGender'),
        disciplinaryCaseDate: any(named: 'disciplinaryCaseDate'),
        academicYearId: any(named: 'academicYearId'),
        title: any(named: 'title'),
        content: any(named: 'content'),
        category: any(named: 'category'),
        severity: any(named: 'severity'),
        sanction: any(named: 'sanction'),
      ),
    ).thenAnswer((_) async => answer);
  }

  void stubUpdate(Either<Failure, void> answer) {
    when(
      () => mockUpdate(
        caseId: any(named: 'caseId'),
        status: any(named: 'status'),
        sanction: any(named: 'sanction'),
        expectedVersion: any(named: 'expectedVersion'),
      ),
    ).thenAnswer((_) async => answer);
  }

  const loadEvent = LoadOfflineDisciplinaryCases(
    studentId: 'stu-1',
    academicYearId: 'ay-1',
  );

  final createEvent = CreateOfflineDisciplinaryCase(
    studentId: 'stu-1',
    studentFirstName: 'John',
    studentLastName: 'Doe',
    studentGender: StudentGender.male,
    disciplinaryCaseDate: DateTime(2026, 3, 12),
    academicYearId: 'ay-1',
    title: 'Bagarre',
    content: 'Altercation dans la cour.',
    category: DisciplinaryCategory.fighting,
    severity: DisciplinarySeverity.serious,
  );

  const updateEvent = UpdateOfflineDisciplinaryCase(
    caseId: 'case-1',
    status: DisciplinaryStatus.resolved,
    sanction: DisciplinarySanction.detention,
    expectedVersion: 3,
  );

  group('chargement', () {
    blocTest<DisciplinaryCaseOfflineBloc, DisciplinaryCaseOfflineState>(
      'emet [loading, casesLoaded] sur succes',
      setUp: () => stubGet(Right([tCase])),
      build: buildBloc,
      act: (bloc) => bloc.add(loadEvent),
      expect: () => [
        const DisciplinaryOfflineLoading(),
        DisciplinaryOfflineCasesLoaded([tCase]),
      ],
    );

    blocTest<DisciplinaryCaseOfflineBloc, DisciplinaryCaseOfflineState>(
      'emet [loading, error] sur StorageFailure',
      setUp: () => stubGet(const Left(StorageFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(loadEvent),
      expect: () => [
        const DisciplinaryOfflineLoading(),
        const DisciplinaryOfflineError('Erreur d\'accès à la base locale.'),
      ],
    );
  });

  group('création', () {
    blocTest<DisciplinaryCaseOfflineBloc, DisciplinaryCaseOfflineState>(
      'emet [saving, pendingSync] sur succes',
      setUp: () => stubCreate(Right(tCase)),
      build: buildBloc,
      act: (bloc) => bloc.add(createEvent),
      expect: () => [
        const DisciplinaryOfflineSaving(),
        DisciplinaryOfflineCasePendingSync(tCase),
      ],
    );

    blocTest<DisciplinaryCaseOfflineBloc, DisciplinaryCaseOfflineState>(
      'emet [saving, error] sur echec',
      setUp: () => stubCreate(const Left(StorageFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(createEvent),
      expect: () => [
        const DisciplinaryOfflineSaving(),
        const DisciplinaryOfflineError('Erreur d\'accès à la base locale.'),
      ],
    );
  });

  group('traitement', () {
    blocTest<DisciplinaryCaseOfflineBloc, DisciplinaryCaseOfflineState>(
      'emet [saving, updated] sur succes',
      setUp: () => stubUpdate(const Right<Failure, void>(null)),
      build: buildBloc,
      act: (bloc) => bloc.add(updateEvent),
      expect: () => [
        const DisciplinaryOfflineSaving(),
        const DisciplinaryOfflineCaseUpdated(),
      ],
    );

    blocTest<DisciplinaryCaseOfflineBloc, DisciplinaryCaseOfflineState>(
      'emet [saving, error] sur ConflictFailure (verrou optimiste)',
      setUp: () => stubUpdate(const Left(ConflictFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(updateEvent),
      expect: () => [
        const DisciplinaryOfflineSaving(),
        const DisciplinaryOfflineError(
          'Version périmée : ce cas a été modifié ailleurs.',
        ),
      ],
    );
  });
}
