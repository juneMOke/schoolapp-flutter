import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_read_api.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';

/// Le programme lu en ligne, pour qui n'a pas le cours sur la tablette (la
/// direction). Lecture seule : aucun geste ne part d'ici. Les évaluations
/// liées ne descendent pas avec le programme : elles ne sont pas comptées.
class ProgrammeOnlineReader {
  final ProgrammeReadApi _api;
  final Map<String, dynamic> _extras;

  const ProgrammeOnlineReader({
    required ProgrammeReadApi api,
    required Map<String, dynamic> extras,
  }) : _api = api,
       _extras = extras;

  Future<Either<Failure, Programme>> readProgramme(String coursId) =>
      _guard(() async {
        final dtos = await _api.chapitresOfCours(_extras, coursId);
        dtos.sort((a, b) => a.ordre.compareTo(b.ordre));
        return Programme(
          coursId: coursId,
          readOnly: true,
          chapitres: [
            for (final dto in dtos)
              ProgrammeChapitre(
                chapitre: dto.toEntity(readOnly: true),
                notesCount: dto.notes.length,
              ),
          ],
        );
      });

  Future<Either<Failure, ChapitreDetail>> readChapitre(String chapitreId) =>
      _guard(() async {
        final dto = await _api.chapitre(_extras, chapitreId);
        return ChapitreDetail(
          chapitre: dto.toEntity(readOnly: true),
          numero: dto.ordre + 1,
        );
      });

  /// Classe l'échec : l'intercepteur range sa [Failure] dans `error` (403 →
  /// [UnauthorizedFailure], 401 → [InvalidCredentialsFailure]) ; sans
  /// réponse, c'est le réseau.
  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right(await read());
    } on DioException catch (e) {
      return Left(ApiErrorParser.failureOf(e));
    } on FormatException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
