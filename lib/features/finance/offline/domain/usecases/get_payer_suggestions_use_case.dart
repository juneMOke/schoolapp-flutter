import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Payeurs proposés d'emblée à l'ouverture de la modale d'encaissement : ceux
/// qui ont déjà payé pour cet élève, puis ses tuteurs déclarés.
class GetPayerSuggestionsUseCase {
  final FinanceOfflineRepository _repository;

  const GetPayerSuggestionsUseCase(this._repository);

  Future<Either<Failure, List<LocalPayerIdentity>>> call(
    String studentId, {
    int limit = 8,
  }) => _repository.getPayerSuggestions(studentId, limit: limit);
}
