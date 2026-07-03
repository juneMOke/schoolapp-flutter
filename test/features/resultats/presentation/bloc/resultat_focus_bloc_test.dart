import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/focus_entete.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/synthese.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultat_focus_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

class MockGetResultatFocusUseCase extends Mock
    implements GetResultatFocusUseCase {}

class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

// Élève non classé : bulletinParDomaine null (cas valide, pas une erreur).
const _tFocus = ResultatFocus(
  classroomId: 'c',
  periodeScolaireId: 'p',
  periodeOrdre: 1,
  entete: FocusEntete(studentId: 's', nom: 'D', prenom: 'J', nbClasses: 10),
  progression: [],
  topMatieres: [],
  bottomMatieres: [],
  synthese: Synthese(nbClasses: 10),
);

const _event = ResultatFocusRequested(
  classroomId: 'c',
  periodeScolaireId: 'p',
  studentId: 's',
);

void main() {
  late MockGetResultatFocusUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(
      const GetResultatFocusParams(
        classroomId: '',
        periodeScolaireId: '',
        studentId: '',
      ),
    );
  });

  setUp(() {
    mockUseCase = MockGetResultatFocusUseCase();
  });

  ResultatFocusBloc buildBloc() =>
      ResultatFocusBloc(getResultatFocus: mockUseCase);

  blocTest<ResultatFocusBloc, ResultatFocusState>(
    'loading puis success (bulletin null = cas valide)',
    setUp: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Right(_tFocus));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(_event),
    expect: () => const [
      ResultatFocusState(
        status: ResultatFocusStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
      ResultatFocusState(
        status: ResultatFocusStatus.success,
        focus: _tFocus,
        errorType: ResultatsErrorType.none,
      ),
    ],
    verify: (_) => verify(() => mockUseCase(any())).called(1),
  );

  final failureCases = <Failure, ResultatsErrorType>{
    const NetworkFailure(): ResultatsErrorType.network,
    const NotFoundFailure(): ResultatsErrorType.notFound,
    const ValidationFailure(): ResultatsErrorType.validation,
    const UnauthorizedFailure(): ResultatsErrorType.forbidden,
    const InvalidCredentialsFailure(): ResultatsErrorType.invalidCredentials,
    const ServerFailure(): ResultatsErrorType.server,
    const StorageFailure(): ResultatsErrorType.storage,
    const AuthFailure(): ResultatsErrorType.auth,
    const _UnmappedFailure(): ResultatsErrorType.unknown,
  };

  for (final entry in failureCases.entries) {
    blocTest<ResultatFocusBloc, ResultatFocusState>(
      'mappe ${entry.key.runtimeType} -> ${entry.value}',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Left(entry.key));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_event),
      expect: () => [
        const ResultatFocusState(
          status: ResultatFocusStatus.loading,
          errorType: ResultatsErrorType.none,
        ),
        ResultatFocusState(
          status: ResultatFocusStatus.failure,
          errorType: entry.value,
        ),
      ],
    );
  }
}
