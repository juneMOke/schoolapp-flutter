import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Combien d'**encaissements** attendent encore d'être remontés.
///
/// C'est le nombre que la liste de relance imprime sous son titre, et sa
/// définition est étroite à dessein : ni les inscriptions, ni les transferts de
/// classe, ni la présence. Le compteur général de la file d'écritures agrège
/// tous les modules — le papier annoncerait un chiffre plus grand que la
/// vérité, et le gabarit dit « encaissement(s) ».
class CountPendingPaymentsUseCase {
  final FinanceOfflineRepository _repository;

  const CountPendingPaymentsUseCase(this._repository);

  Future<Either<Failure, int>> call() => _repository.countPendingPayments();
}
