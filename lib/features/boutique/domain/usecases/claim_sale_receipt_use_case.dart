import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_receipt_repository.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';

/// Réclame le reçu scellé d'une vente déjà encaissée.
///
/// Voir [BoutiqueReceiptRepository] pour la raison d'être de ce geste : le
/// scellement serveur est *best-effort*, et sans réclamation la promesse « la
/// caisse récupérera le scellé » n'est tenue par rien.
class ClaimSaleReceiptUseCase {
  final BoutiqueReceiptRepository _repository;

  const ClaimSaleReceiptUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(String saleId) =>
      _repository.claimSaleReceipt(saleId);
}
