import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';

/// Note qu'un ticket est sorti de l'imprimante.
///
/// **Ne rend rien.** C'est un renseignement d'affichage, pas de l'argent : il
/// ne part jamais au serveur, et le perdre ne coûte qu'une mention.
class MarkSaleTicketPrintedUseCase {
  final BoutiqueHistoryRepository _repository;

  const MarkSaleTicketPrintedUseCase(this._repository);

  Future<void> call(String saleId) => _repository.markTicketPrinted(saleId);
}
