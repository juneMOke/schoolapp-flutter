import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// La grille tarifaire est-elle présente sur cet appareil pour cette année ?
///
/// Sert à distinguer les deux causes d'une liste de créances vide au wizard :
/// « ce niveau n'a pas de frais » (information) et « la grille n'a pas été
/// hydratée ici » (absence de donnée). La première laisse poursuivre, la
/// seconde doit bloquer — annoncer 0 F à une famille sur une grille absente
/// fait manquer l'encaissement du jour.
class HasFeeGridUseCase {
  final FinanceOfflineRepository _repository;

  const HasFeeGridUseCase(this._repository);

  Future<Either<Failure, bool>> call(String academicYearId) =>
      _repository.hasFeeGridForYear(academicYearId);
}
