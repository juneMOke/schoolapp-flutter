import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_payer_repository.dart';

/// Le payeur déjà connu pour ce numéro, ou `null`.
///
/// **Ne remonte jamais d'erreur** : c'est une lecture de confort, qui évite une
/// ressaisie. Une base illisible doit donner « numéro inconnu » — ce que le
/// guichet sait traiter — et surtout pas un écran d'erreur au milieu d'une
/// vente.
class FindBoutiquePayerUseCase {
  final BoutiquePayerRepository _repository;

  const FindBoutiquePayerUseCase(this._repository);

  Future<BoutiquePayer?> call(String phoneNumber) async {
    final result = await _repository.findByPhone(phoneNumber);
    return result.fold(
      (_) => null,
      (payers) => payers.isEmpty ? null : payers.first,
    );
  }
}
