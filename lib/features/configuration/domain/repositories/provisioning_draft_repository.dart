import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/data/local/provisioning_draft_dao.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';

/// Le brouillon de mise en service, du point de vue de l'assistant.
///
/// **Il appartient à l'appareil.** Sur un autre téléphone, l'assistant repart de
/// zéro — sauf l'étape 1, qui est relue du serveur. C'est à dire dans le lien de
/// reprise plutôt qu'à laisser découvrir.
abstract class ProvisioningDraftRepository {
  /// Brouillon de la session en cours, `null` s'il n'y en a pas.
  ///
  /// Une lecture ne remonte jamais d'échec : un brouillon illisible ou une base
  /// muette valent « pas de brouillon », et l'assistant s'ouvre vierge. Refuser
  /// d'ouvrir enfermerait l'agent hors du seul écran qui peut le débloquer.
  Future<ProvisioningDraft?> load();

  /// Enregistre le brouillon et la progression.
  Future<Either<Failure, Unit>> save({
    required ProvisioningRequest request,
    required int step,
    required int maxStep,
  });

  /// Détruit le brouillon — **au succès de l'activation seulement**.
  Future<Either<Failure, Unit>> clear();
}
