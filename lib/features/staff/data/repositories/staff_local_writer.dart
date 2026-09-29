import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

/// Qui écrit, et pour quelle école : estampillé à la saisie, c'est la valeur
/// que le serveur comparera.
typedef StaffWriteSession = ({String schoolId, String authorId});

/// Le squelette partagé des écritures RH sur la tablette : une session
/// (école + auteur), une écriture locale avec son entrée d'outbox, puis la
/// relance du flush, sans l'attendre.
class StaffLocalWriter {
  final CurrentUserContext _currentUser;

  /// `null` dans les tests qui n'en ont pas besoin.
  final SyncEngine? _syncEngine;

  const StaffLocalWriter({
    required CurrentUserContext currentUser,
    SyncEngine? syncEngine,
  }) : _currentUser = currentUser,
       _syncEngine = syncEngine;

  static const Failure noSession = AuthFailure(
    'Aucune session pour enregistrer',
  );

  /// L'école et l'auteur courants, ou `null` hors session.
  StaffWriteSession? session() {
    final schoolId = _currentUser.schoolId ?? '';
    final authorId = _currentUser.uid;
    if (schoolId.isEmpty || authorId == null) return null;
    return (schoolId: schoolId, authorId: authorId);
  }

  /// Exécute [write] ; un échec local devient un [StorageFailure] nommé
  /// [what]. Un succès relance l'envoi.
  Future<Either<Failure, Unit>> run(
    String what,
    Future<void> Function() write,
  ) async {
    try {
      await write();
    } catch (e) {
      return Left(StorageFailure('$what : $e'));
    }
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return const Right(unit);
  }
}
