import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';

/// Les modèles de communiqué de l'école, en ligne.
abstract class AnnouncementTemplateRepository {
  Future<Either<Failure, List<AnnouncementTemplate>>> list();

  Future<Either<Failure, AnnouncementTemplate>> create({
    required AnnouncementCategory category,
    required String title,
    required String body,
  });

  Future<Either<Failure, AnnouncementTemplate>> update(
    AnnouncementTemplate template,
  );

  /// Retire le modèle ; les communiqués déjà envoyés n'en dépendent pas.
  Future<Either<Failure, Unit>> delete(String id);
}
