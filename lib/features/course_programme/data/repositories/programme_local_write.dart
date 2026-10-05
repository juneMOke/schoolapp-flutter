import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

/// Un geste local du programme : il écrit, puis tente un envoi opportuniste
/// si le poste est en ligne. Une écriture qui échoue n'a rien mis en file.
Future<Either<Failure, T>> writeProgrammeLocally<T>(
  SyncEngine? engine,
  Future<void> Function() write,
  T result,
) async {
  try {
    await write();
  } catch (e) {
    return Left(StorageFailure(e.toString()));
  }
  if (engine != null) unawaited(engine.flush());
  return Right(result);
}
