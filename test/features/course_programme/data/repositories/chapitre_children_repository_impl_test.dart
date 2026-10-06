import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_children_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/chapitre_children_repository_impl.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_transfer_api.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';

import '../../programme_test_fakes.dart';

class _MockWriter extends Mock implements ChapitreChildrenWriteDao {}

class _MockTransfer extends Mock implements ProgrammeTransferApi {}

class _MockIds extends Mock implements IdGenerator {}

/// Ouvrir un document : la copie de la tablette d'abord ; sinon le
/// téléchargement, confronté à son empreinte, puis gardé.
void main() {
  late FakeProgrammeBlobs blobs;
  late _MockTransfer transfer;
  late ChapitreChildrenRepositoryImpl repository;
  final bytes = Uint8List.fromList([1, 2, 3]);

  ChapitreRessource ressource({String? sha}) => ChapitreRessource(
    id: 'r-1',
    chapitreId: 'ch-1',
    type: RessourceType.document,
    nom: 'Fiche',
    sha256: sha,
  );

  setUp(() {
    blobs = FakeProgrammeBlobs();
    transfer = _MockTransfer();
    repository = ChapitreChildrenRepositoryImpl(
      writer: _MockWriter(),
      blobs: blobs,
      transfer: transfer,
      ids: _MockIds(),
      currentUser: CurrentUserContext(),
      extras: const {},
    );
  });

  test('la copie de la tablette, sans réseau', () async {
    blobs.files['r-1'] = bytes;
    final result = await repository.openDocument(ressource());
    expect(result.getOrElse(() => Uint8List(0)), bytes);
    verifyNever(
      () => transfer.download(
        any(),
        chapitreId: any(named: 'chapitreId'),
        ressourceId: any(named: 'ressourceId'),
      ),
    );
  });

  test('téléchargée, vérifiée, puis gardée', () async {
    when(
      () => transfer.download(const {}, chapitreId: 'ch-1', ressourceId: 'r-1'),
    ).thenAnswer((_) async => bytes);

    final result = await repository.openDocument(
      ressource(sha: await sha256Hex(bytes)),
    );

    expect(result.isRight(), isTrue);
    expect(blobs.files['r-1'], bytes);
  });

  test(
    'une empreinte qui ne correspond pas n\'est ni montrée ni gardée',
    () async {
      when(
        () =>
            transfer.download(const {}, chapitreId: 'ch-1', ressourceId: 'r-1'),
      ).thenAnswer((_) async => bytes);

      final result = await repository.openDocument(ressource(sha: 'autre'));

      expect(result.fold((f) => f, (_) => null), isA<IntegrityFailure>());
      expect(blobs.files, isEmpty);
    },
  );

  test('hors ligne : un échec réseau', () async {
    when(
      () => transfer.download(const {}, chapitreId: 'ch-1', ressourceId: 'r-1'),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));

    final result = await repository.openDocument(ressource());

    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
  });
}
