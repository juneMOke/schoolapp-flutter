import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';

/// Une classe chargée. [fromCache] : le serveur n'a pas pu répondre, l'écran
/// travaille sur la dernière copie de l'appareil.
class CoteSnapshot extends Equatable {
  final CoteClasse classe;
  final List<CoteCell> cells;
  final bool fromCache;

  const CoteSnapshot({
    required this.classe,
    required this.cells,
    required this.fromCache,
  });

  @override
  List<Object?> get props => [classe, cells, fromCache];
}

/// Où en est l'envoi après un vidage de la file.
enum CoteFlushOutcome {
  /// Plus rien à envoyer pour cet auteur dans cette classe.
  done,

  /// Pas de réseau : la file attend.
  offline,

  /// La session ne peut plus authentifier ses appels : la file attend la
  /// reconnexion.
  sessionExpired,

  /// Il reste des lignes : panne ou refus.
  stuck,

  /// Un autre vidage est en cours : son issue sera signalée.
  busy,
}

abstract interface class CotesRepository {
  /// Le serveur d'abord, le cache s'il ne répond pas. Sans cache, l'échec du
  /// réseau remonte. Un refus de droits remonte toujours, même avec un cache.
  Future<Either<Failure, CoteSnapshot>> load(String classroomId);

  /// Pose une saisie valide et l'enfile, sans la pousser ; `null` vide la
  /// cellule. Le réseau part avec [flush], après le délai de frappe.
  Future<Either<Failure, Unit>> saveValue({
    required String classroomId,
    required CoteCellKey key,
    required double? value,
  });

  /// Garde une frappe hors barème, sans l'envoyer.
  Future<Either<Failure, Unit>> saveInvalid({
    required String classroomId,
    required CoteCellKey key,
    required String raw,
  });

  Future<Either<Failure, Unit>> clearInvalid(CoteCellKey key);

  /// Renonce à une cote refusée.
  Future<Either<Failure, Unit>> discardRejected(CoteCellKey key);

  Future<Either<Failure, List<CoteCell>>> readCells(String classroomId);

  /// Les cellules dépassées par une écriture plus récente, signalées une fois.
  Future<Either<Failure, List<CoteCellKey>>> takeSuperseded(String classroomId);

  /// Les cotes de cet auteur encore à envoyer dans cette classe.
  Future<int> pendingCount(String classroomId);

  Future<CoteFlushOutcome> flush(String classroomId);

  /// Remet la classe en tête de file, sans délai de reprise (« Réessayer »).
  Future<void> retry(String classroomId);

  /// S'abonne à la fin de chaque vidage ; rend le désabonnement.
  void Function() addFlushListener(void Function() listener);
}
