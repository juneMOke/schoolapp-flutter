import 'dart:convert';

import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_receipt_recovery_dao.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_receipt_repository.dart';
import 'package:school_app_flutter/core/offline/outbox_permission_guard.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';

/// Réclame le reçu de vente qu'un accusé n'a pas rapporté.
///
/// Pendant de `PaymentReceiptRecoveryOutboxHandler` : la route
/// `POST /boutique/sales/{id}/receipt` est idempotente sous verrou, donc toute
/// reprise est sans danger. La réclamation elle-même consigne numéro, jour
/// d'émission et QR sur la vente (`BoutiqueReceiptRepository`) ; le ticket
/// devient alors imprimable.
class BoutiqueSaleReceiptRecoveryHandler
    implements OutboxWriteAccess, OutboxSyncHandler {
  final BoutiqueReceiptRepository Function() _receipts;
  final BoutiqueReceiptRecoveryDao _dao;
  final CurrentUserContext _currentUser;

  const BoutiqueSaleReceiptRecoveryHandler({
    required BoutiqueReceiptRepository Function() receipts,
    required BoutiqueReceiptRecoveryDao dao,
    required CurrentUserContext currentUser,
  }) : _receipts = receipts,
       _dao = dao,
       _currentUser = currentUser;

  @override
  String get aggregateType => BoutiqueReceiptRecoveryDao.aggregateType;

  @override
  ModuleAccess? writeAccessFor(OutboxEntry entry) => kBoutiqueCollectAccess;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    final String saleId;
    try {
      final map = jsonDecode(entry.payload) as Map<String, dynamic>;
      saleId = map[BoutiqueReceiptRecoveryDao.saleIdKey] as String;
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }

    // La vente a quitté ce poste, ou son numéro est arrivé entre-temps (pull,
    // réclamation à la main) : plus rien à réclamer.
    final known = await _dao.receiptNumberOf(saleId);
    if (known == null || known.isNotEmpty) {
      return const OutboxDispatchResult.acked();
    }

    final claimed = await _receipts().claimSaleReceipt(saleId);
    if (claimed.isLeft()) {
      return claimed.fold(_refused, (_) => const OutboxDispatchResult.acked());
    }
    // Ce qui compte, c'est ce que la BASE porte désormais : la réclamation
    // consigne sans lever, et un numéro rendu mais non écrit laisserait le
    // ticket bloqué. Le rejeu rend la même pièce.
    final stored = await _dao.receiptNumberOf(saleId);
    if (stored == null) return const OutboxDispatchResult.acked();
    return stored.isEmpty
        ? const OutboxDispatchResult.retry('Numéro du reçu non consigné')
        : const OutboxDispatchResult.acked();
  }

  static OutboxDispatchResult _refused(Failure failure) {
    final code = failure is ApiErrorDetails ? failure.detailCode : null;
    final reason = code == null
        ? failure.message
        : '$code — ${failure.message}';
    return switch (failure) {
      // Vente inconnue, refus nommé : la marque reste visible en échec, et
      // « Réclamer le reçu » sur la fiche reste offert.
      NotFoundFailure() ||
      ValidationFailure() => OutboxDispatchResult.failed(reason),
      // Réseau, 401, 403, 409, 429, 5xx, issue inconnue : la route est
      // idempotente, on réessaie.
      _ => OutboxDispatchResult.retry(reason),
    };
  }
}
