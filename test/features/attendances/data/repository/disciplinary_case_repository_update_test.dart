import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/update_disciplinary_case_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/disciplinary_case_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/disciplinary_case_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';

class MockRemote extends Mock implements DisciplinaryCaseRemoteDataSource {}

class FakeUpdate extends Fake implements UpdateDisciplinaryCaseRequestModel {}

void main() {
  late MockRemote remote;
  late DisciplinaryCaseRepositoryImpl repo;
  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() => registerFallbackValue(FakeUpdate()));

  setUp(() {
    remote = MockRemote();
    repo = DisciplinaryCaseRepositoryImpl(
      remoteDataSource: remote,
      requiredAuth: auth,
    );
  });

  test(
    'updateDisciplinaryCaseStatus succès → Right + sanction courante envoyée',
    () async {
      when(
        () => remote.updateDisciplinaryCase(any(), any(), any()),
      ).thenAnswer((_) async {});

      final result = await repo.updateDisciplinaryCaseStatus(
        caseId: 'case-1',
        status: DisciplinaryStatus.resolved,
        sanction: DisciplinarySanction.detention,
      );

      expect(result.isRight(), isTrue);
      final captured =
          verify(
                () =>
                    remote.updateDisciplinaryCase(auth, 'case-1', captureAny()),
              ).captured.single
              as UpdateDisciplinaryCaseRequestModel;
      expect(captured.status, 'RESOLVED');
      expect(captured.sanction, 'DETENTION');
    },
  );

  test('409 → ConflictFailure propagé (verrou optimiste périmé)', () async {
    when(() => remote.updateDisciplinaryCase(any(), any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/disciplinary-cases/case-1'),
        error: const ConflictFailure(),
      ),
    );

    final result = await repo.updateDisciplinaryCaseStatus(
      caseId: 'case-1',
      status: DisciplinaryStatus.resolved,
      sanction: DisciplinarySanction.detention,
    );

    expect(result, isA<Left<Failure, void>>());
    result.fold((f) => expect(f, isA<ConflictFailure>()), (_) => fail('right'));
  });
}
