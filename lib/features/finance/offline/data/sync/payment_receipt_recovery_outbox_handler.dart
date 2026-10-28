import 'dart:convert';

import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/receipt_recovery_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_error_codes.dart';

/// Va chercher le reçu qu'un accusé n'a pas rapporté (continuité RC).
///
/// `POST /finance/payments/{id}/receipt` rend le reçu s'il existe et le scelle
/// sinon, sans consommer de numéro en plus — timeout compris. D'où une
/// classification plus douce que celle des émissions : tout ce qui n'est pas
/// un refus nommé se rejoue.
///
/// Avant la release back qui verrouille le versement, une relance arrivée
/// pendant le premier scellement répond 409 : c'est un « réessayer plus
/// tard » comme un autre.
class PaymentReceiptRecoveryOutboxHandler implements OutboxSyncHandler {
  /// Résolu à l'appel : le dépôt d'éditique vit hors des modules offline, et
  /// le handler s'enregistre avec eux.
  final EditiqueRepository Function() _editique;
  final ReceiptRecoveryDao _dao;
  final CurrentUserContext _currentUser;

  const PaymentReceiptRecoveryOutboxHandler({
    required EditiqueRepository Function() editique,
    required ReceiptRecoveryDao dao,
    required CurrentUserContext currentUser,
  }) : _editique = editique,
       _dao = dao,
       _currentUser = currentUser;

  @override
  String get aggregateType => ReceiptRecoveryDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    final String paymentId;
    try {
      final map = jsonDecode(entry.payload) as Map<String, dynamic>;
      paymentId = map[ReceiptRecoveryDao.paymentIdKey] as String;
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }

    // Le versement a quitté ce poste (refusé, purgé) : plus rien à attester.
    final scope = await _dao.scopeOf(paymentId);
    if (scope == null) return const OutboxDispatchResult.acked();

    final result = await _editique().emitPaymentReceipt(
      paymentId: paymentId,
      studentId: scope.studentId,
      academicYearId: scope.academicYearId,
    );
    return result.fold(
      _classify,
      (document) => _recovered(paymentId, document),
    );
  }

  Future<OutboxDispatchResult> _recovered(
    String paymentId,
    EditiqueDocument document,
  ) async {
    await _dao.recordRecovered(
      paymentId: paymentId,
      documentId: document.documentId,
      documentNumber: document.documentNumber,
    );
    return const OutboxDispatchResult.acked();
  }

  /// Un refus nommé tranche ; tout le reste se rejoue sans risque.
  static OutboxDispatchResult _classify(Failure failure) {
    final code = failure is ApiErrorDetails ? failure.detailCode : null;
    // Annulé entre-temps : la marque n'a plus d'objet. `acked` dit ici « le
    // serveur a tranché », comme pour un agrégat supprimé.
    if (code == FinanceErrorCodes.paymentCancelled) {
      return const OutboxDispatchResult.acked();
    }
    return switch (failure) {
      // 403 (droit `editique.write` retiré), versement inconnu, autre refus :
      // la marque reste visible, « Relancer » la fera repartir.
      UnauthorizedFailure() || NotFoundFailure() || ValidationFailure() =>
        OutboxDispatchResult.failed(_reasonOf(failure, code)),
      // Réseau, 401, 409, 429, 5xx, issue inconnue : la route est idempotente.
      _ => OutboxDispatchResult.retry(_reasonOf(failure, code)),
    };
  }

  static String _reasonOf(Failure failure, String? code) =>
      code == null ? failure.message : '$code — ${failure.message}';
}
