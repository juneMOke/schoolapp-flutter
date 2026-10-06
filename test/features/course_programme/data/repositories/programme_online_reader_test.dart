import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/programme_online_reader.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_read_api.dart';

class _MockApi extends Mock implements ProgrammeReadApi {}

void main() {
  late _MockApi api;
  late ProgrammeOnlineReader reader;

  const dto = ChapitreDto(
    id: 'ch-2',
    coursId: 'c-1',
    ordre: 1,
    titre: 'Décimaux',
    statut: 'TERMINE',
    seances: 3,
    notes: [
      ChapitreNoteDto(id: 'n', texte: 't', ecriteLe: '2026-10-01T00:00:00Z'),
    ],
  );

  setUp(() {
    api = _MockApi();
    reader = ProgrammeOnlineReader(api: api, extras: const {});
  });

  test('le programme en ligne, dans l\'ordre, notes comptées', () async {
    when(() => api.chapitresOfCours(const {}, 'c-1')).thenAnswer(
      (_) async => [
        dto,
        const ChapitreDto(
          id: 'ch-1',
          coursId: 'c-1',
          ordre: 0,
          titre: 'Entiers',
          statut: 'PLANIFIE',
          seances: 4,
        ),
      ],
    );

    final programme = (await reader.readProgramme(
      'c-1',
    )).getOrElse(() => fail('Left'));

    expect(programme.chapitres.map((r) => r.chapitre.id), ['ch-1', 'ch-2']);
    expect(programme.chapitres.last.notesCount, 1);
  });

  test('le 403 rangé par l\'intercepteur reste un 403', () async {
    when(() => api.chapitre(const {}, 'ch-2')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/'),
        error: const UnauthorizedFailure(),
      ),
    );

    final result = await reader.readChapitre('ch-2');

    expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
  });

  test('sans réponse : le réseau', () async {
    when(
      () => api.chapitresOfCours(const {}, 'c-1'),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));

    final result = await reader.readProgramme('c-1');

    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
  });

  test('le numéro d\'un chapitre lu en ligne suit son rang', () async {
    when(() => api.chapitre(const {}, 'ch-2')).thenAnswer((_) async => dto);
    final detail = (await reader.readChapitre(
      'ch-2',
    )).getOrElse(() => fail('Left'));
    expect(detail.numero, 2);
  });
}
