import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Popin « Choisir un payeur » : recherche locale d'un payeur déjà venu à la
/// caisse, par numéro OU par identité.
class SearchPayersUseCase {
  final FinanceOfflineRepository _repository;

  const SearchPayersUseCase(this._repository);

  Future<Either<Failure, List<LocalPayerIdentity>>> call({
    String? lastName,
    String? firstName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  }) => _repository.searchPayers(
    lastName: lastName,
    firstName: firstName,
    surname: surname,
    phoneNumber: phoneNumber,
    limit: limit,
  );
}
