import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/fee_code_section_cache_repository.dart';

/// Descend une fois par session les titres de sections écrits par l'école.
///
/// Rend le nombre de titres retenus — `0` quand la session avait déjà tiré, ou
/// quand rien n'a pu être obtenu. L'appelant s'en sert pour décider s'il vaut la
/// peine de relire le cache.
class RefreshFeeSectionTitlesUseCase {
  final FeeCodeSectionCacheRepository _repository;

  const RefreshFeeSectionTitlesUseCase(this._repository);

  Future<Either<Failure, int>> call() => _repository.ensureFeeSectionTitles();
}
