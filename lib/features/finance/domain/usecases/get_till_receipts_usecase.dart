import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipts_page.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

/// La preuve, ligne par ligne : les reçus **d'une caisse** sur la fenêtre.
///
/// Un second appel, subordonné au premier — le même rapport que la liste
/// nominative du jour au tableau de bord des inscriptions. Il porte une
/// **seconde permission** (`finance.payment.read`), et son échec ne doit pas
/// emporter les agrégats : les cartes viennent d'un appel qui a réussi.
///
/// [currency] n'a pas de défaut : la table décrit une caisse, et en choisir une
/// ici cacherait la question au lieu de la poser.
class GetTillReceiptsUseCase {
  final FinanceRepository _repository;

  const GetTillReceiptsUseCase(this._repository);

  Future<Either<Failure, TillReceiptsPage>> call({
    required String currency,
    TillWindow window = const TillWindow.day(),
    int page = 0,
    int size = TillReceiptsQuery.defaultPageSize,
  }) => _repository.getTillReceipts(
    currency: currency,
    window: window,
    page: page,
    size: size,
  );
}
