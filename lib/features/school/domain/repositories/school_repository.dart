import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';

/// Identité de l'établissement courant — lecture **100 % locale** du
/// référentiel Inscription déjà pullé (`ref_school`). Aucun appel réseau : ce
/// cache est rempli par le pull référentiel que le gate de démarrage garantit.
abstract class SchoolRepository {
  /// Établissement de la session courante.
  ///
  /// `Right(null)` = identité indisponible — pas de session, référentiel pas
  /// encore synchronisé, ou ligne appartenant à une **autre** école que celle
  /// de la session (device multi-école). C'est un état légitime, jamais un
  /// échec : l'appelant se rabat sur un libellé générique.
  Future<Either<Failure, School?>> loadCurrentSchool();
}
