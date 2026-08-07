import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Numéro du reçu (RC) d'un paiement, tel qu'il est connu localement.
///
/// Rend `null` dès que l'information n'est pas disponible — pas de reçu local,
/// ou base illisible. Une lecture d'affichage ne remonte jamais d'erreur :
/// l'absence de numéro se rend par un libellé neutre, elle ne doit pas
/// transformer le détail d'un paiement en écran d'erreur.
class GetPaymentReceiptDocumentUseCase {
  final FinanceOfflineRepository _repository;

  const GetPaymentReceiptDocumentUseCase(this._repository);

  Future<LocalGeneratedDocument?> call(String paymentId) async {
    if (paymentId.trim().isEmpty) return null;
    final result = await _repository.getPaymentReceipt(paymentId);
    return result.fold((_) => null, (document) => document);
  }
}
