import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';

/// Les communiqués, **en ligne seulement** : aucune file d'attente, aucun flux
/// `/sync`. Chaque geste renvoie le communiqué entier, avec sa nouvelle
/// `version`.
///
/// Un refus métier arrive en [ApiValidationFailure] (422) dont le
/// `detailCode` vaut `ANNOUNCEMENT_*`.
abstract class AnnouncementRepository {
  /// Les communiqués de l'année, annulés exclus ; filtrage côté client.
  Future<Either<Failure, List<Announcement>>> list({String? academicYearId});

  Future<Either<Failure, Announcement>> get(String id);

  /// Crée le brouillon [id] — un UUID de la tablette. Rejoué avec le même
  /// [id], le serveur rend le brouillon existant.
  Future<Either<Failure, Announcement>> create({
    required String id,
    required AnnouncementContent content,
    String? academicYearId,
  });

  /// Remplace le contenu ; `DRAFT`, ou `SCHEDULED` dont l'heure n'est pas
  /// passée.
  Future<Either<Failure, Announcement>> update(
    String id,
    AnnouncementContent content, {
    required int version,
  });

  Future<Either<Failure, Announcement>> schedule(
    String id, {
    required DateTime scheduledAt,
    required int version,
  });

  Future<Either<Failure, Announcement>> unschedule(
    String id, {
    required int version,
  });

  /// Rejoué sur un communiqué déjà envoyé, rend 200 sans rien renvoyer aux
  /// parents.
  Future<Either<Failure, Announcement>> send(String id, {required int version});

  Future<Either<Failure, Announcement>> cancel(
    String id, {
    required int version,
  });
}
