import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';

/// Les copies déposées par les parents pour un devoir en ligne : lues dans le
/// miroir local (elles descendent avec l'évaluation), ouvertes à la demande.
abstract class DepotCopieRepository {
  Future<Either<Failure, List<DepotCopie>>> depots(String evaluationId);

  /// Les octets d'une page. `NetworkFailure` hors connexion quand elle n'est
  /// pas déjà dans le dossier temporaire de la session.
  Future<Either<Failure, Uint8List>> fichier(
    String evaluationId,
    DepotFichier fichier,
  );
}
