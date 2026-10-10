import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/features/class_journal/data/online/journal_read_api.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_read_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_teacher.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_direction_repository.dart';

/// Les journaux lus en ligne : l'intercepteur range sa [Failure] dans
/// l'erreur Dio (403 → [UnauthorizedFailure], 401 →
/// [InvalidCredentialsFailure]) ; sans réponse, c'est le réseau.
class JournalDirectionRepositoryImpl implements JournalDirectionRepository {
  final JournalReadApi _api;
  final Map<String, dynamic> _extras;

  const JournalDirectionRepositoryImpl({
    required JournalReadApi api,
    required Map<String, dynamic> extras,
  }) : _api = api,
       _extras = extras;

  @override
  Future<Either<Failure, List<JournalTeacher>>> teachers() =>
      _guard(() => _api.teachers(_extras));

  @override
  Future<Either<Failure, List<JournalReadLine>>> dayOf(
    String teacherId,
    DateTime date,
  ) => _guard(() => _api.dayOf(_extras, teacherId, date));

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right(await read());
    } on DioException catch (e) {
      return Left(ApiErrorParser.failureOf(e));
    } catch (e) {
      // Une réponse illisible ne doit pas laisser la page en chargement.
      return Left(ServerFailure(e.toString()));
    }
  }
}
