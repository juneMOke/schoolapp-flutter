import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
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
      guardOnline(() => _api.teachers(_extras));

  @override
  Future<Either<Failure, List<JournalReadLine>>> dayOf(
    String teacherId,
    DateTime date,
  ) => guardOnline(() => _api.dayOf(_extras, teacherId, date));
}
