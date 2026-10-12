import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';

/// Le référentiel de ciblage, lu sur la tablette : rapide et hors réseau,
/// même si l'envoi, lui, est en ligne.
abstract class AudienceReferentialRepository {
  Future<Either<Failure, AudienceReferential>> load(String academicYearId);
}
