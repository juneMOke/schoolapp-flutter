import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/grantable_reduction.dart';

/// Réductions au guichet (ADR-021 V1) : ce qu'on peut octroyer, et ce qui l'est.
///
/// Deux sources, une seule façade : le **catalogue** appartient à la
/// Facturation (il descend avec le référentiel, derrière `finance.grid.read`),
/// l'**octroi** appartient à l'inscription. L'écran n'a pas à connaître cette
/// couture.
abstract class ReductionGrantRepository {
  /// Les réductions proposables pour l'école de la session. Liste vide = rien
  /// à proposer, quelle qu'en soit la raison (droit manquant, école sans
  /// barème, serveur qui ne porte pas encore les sections).
  Future<Either<Failure, List<GrantableReduction>>> grantable();

  /// Les codes déjà octroyés à cette inscription.
  Future<Either<Failure, List<String>>> grantedFor(String enrollmentId);

  /// Remplace les octrois de cette inscription (décocher retire).
  Future<Either<Failure, Unit>> replaceGrants(
    String enrollmentId,
    List<String> codes,
  );
}
