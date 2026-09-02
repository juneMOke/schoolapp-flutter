import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Les titres de sections de frais de l'école, lus en local.
///
/// Indexés par nature (`TUITION` → « Frais scolaires »). Ce que l'école a écrit,
/// pas ce que l'application traduit — et rien du tout tant que le catalogue
/// n'est pas descendu, auquel cas les écrans nomment par la nature localisée.
class GetFeeSectionTitlesUseCase {
  final FinanceOfflineRepository _repository;

  const GetFeeSectionTitlesUseCase(this._repository);

  Future<Either<Failure, Map<String, String>>> call() =>
      _repository.getFeeSectionTitles();
}
