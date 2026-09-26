import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_receipt_lookup_dao.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';

/// Résout le reçu d'un versement en **deux lectures**, une par base.
///
/// 1. Base de l'école : la ligne RC locale et `payments.receipt_id`.
/// 2. `device.db` : le cache des pièces, par identifiant — c'est lui qui connaît
///    le numéro scellé et l'annulation d'un reçu émis sur une autre caisse.
///
/// ⚠️ Pas `FindCachedDocumentUseCase` : il ne rend que les pièces détenues ou
/// annulées. Un reçu seulement appris par le pull, sans PDF, y revient `null`
/// alors que son numéro est connu.
class PaymentReceiptResolverImpl implements PaymentReceiptResolver {
  final PaymentReceiptLookupDao _local;
  final EditiqueCacheDao _cache;
  final EditiqueCacheAccess _access;
  final CurrentUserContext _currentUser;

  const PaymentReceiptResolverImpl({
    required PaymentReceiptLookupDao local,
    required EditiqueCacheDao cache,
    required EditiqueCacheAccess access,
    required CurrentUserContext currentUser,
  }) : _local = local,
       _cache = cache,
       _access = access,
       _currentUser = currentUser;

  @override
  Future<PaymentReceiptReference> resolve(String paymentId) async {
    if (paymentId.trim().isEmpty) return const PaymentReceiptReference();

    final PaymentReceiptLocalRow row;
    try {
      row = await _local.find(paymentId);
    } catch (_) {
      return const PaymentReceiptReference();
    }

    final localDefinitive = row.documentStatus == 'DEFINITIVE'
        ? row.documentNumber
        : null;
    final cached = await _findInCache(
      documentId: row.receiptId,
      documentNumber: localDefinitive,
    );
    final cachedNumber = _text(cached?.documentNumber);

    // Le numéro scellé local d'abord, puis celui du cache : un versement
    // encaissé ailleurs n'a que le second. Le `PROV-…` ne vient qu'après — un
    // reçu dont le serveur a rendu l'identifiant n'est plus provisoire, même
    // si le scellement local a échoué.
    final (number, status) = switch ((localDefinitive, cachedNumber)) {
      (final String n, _) => (n, PaymentReceiptStatus.definitive),
      (null, final String n) => (n, PaymentReceiptStatus.definitive),
      _ => _provisional(row),
    };

    return PaymentReceiptReference(
      number: number,
      status: status,
      documentId: row.receiptId ?? _text(cached?.documentId),
      cacheEntry: cached,
      paymentCancelledAt: row.paymentCancelledAt,
    );
  }

  /// Le `PROV-…` local : la colonne provisoire d'abord (elle survit au
  /// scellement), le numéro sinon.
  static (String?, PaymentReceiptStatus) _provisional(
    PaymentReceiptLocalRow row,
  ) {
    final number = row.provisionalNumber ?? row.documentNumber;
    return number == null
        ? (null, PaymentReceiptStatus.unknown)
        : (number, PaymentReceiptStatus.provisional);
  }

  /// Par identifiant d'abord ; par numéro, scopé à l'école, seulement quand
  /// aucun identifiant n'est connu (régime AM-5).
  ///
  /// La garde de profil (RG-012-4) s'applique ici comme à tout lecteur du
  /// cache : sans droit, la tablette ne sait rien de la pièce.
  Future<EditiqueCacheEntry?> _findInCache({
    required String? documentId,
    required String? documentNumber,
  }) async {
    try {
      if (!await _access.isEntitled()) return null;
      if (documentId != null) {
        final byId = await _cache.findByDocumentId(documentId);
        if (byId != null) return byId;
      }
      final schoolId = _currentUser.schoolId;
      if (documentNumber == null || schoolId == null || schoolId.isEmpty) {
        return null;
      }
      return await _cache.findByDocumentNumber(
        schoolId: schoolId,
        documentNumber: documentNumber,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _text(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
