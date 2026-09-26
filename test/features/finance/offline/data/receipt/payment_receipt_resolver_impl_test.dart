import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_receipt_lookup_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/receipt/payment_receipt_resolver_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';

import '../../../../documents/data/local/editique_cache_fixtures.dart';
import '../../../../offline_full_db.dart';

/// Une pièce apprise par le pull des pièces : métadonnées seules, aucun octet
/// téléchargé sur cette tablette.
EditiqueCacheEntry _knownOnly({
  String documentNumber = 'CF-RC-2627-000279',
  int? cancelledAt,
  String? cancellationReason,
}) => EditiqueCacheEntry(
  id: 'c-9',
  documentId: 'doc-9',
  documentNumber: documentNumber,
  docType: 'RC',
  studentId: 's-1',
  schoolId: 'school-1',
  ownerUid: 'u-1',
  sizeBytes: 0,
  cancelledAt: cancelledAt,
  cancellationReason: cancellationReason,
  createdAt: 2000,
  lastAccessedAt: 3000,
);

class _Access implements EditiqueCacheAccess {
  bool entitled = true;

  @override
  Future<bool> isEntitled() async => entitled;
}

/// Le résolveur lit DEUX fichiers, comme en production : la base de l'école
/// (sans le cache des pièces) et `device.db` (sans `payments`). Une jointure
/// entre les deux lèverait ici au lieu de passer.
void main() {
  late Database school;
  late Database device;
  late EditiqueCacheDao cache;
  late _Access access;
  late PaymentReceiptResolverImpl resolver;

  setUp(() async {
    school = await openTenantTestDb();
    device = await openDeviceTestDb();
    cache = EditiqueCacheDao(device);
    access = _Access();
    resolver = PaymentReceiptResolverImpl(
      local: PaymentReceiptLookupDao(school),
      cache: cache,
      access: access,
      currentUser: CurrentUserContext()..set('u-1', schoolId: 'school-1'),
    );
  });

  tearDown(() async {
    await school.close();
    await device.close();
  });

  Future<void> seedPayment({String? receiptId, int? cancelledAt}) =>
      school.insert('payments', {
        'id': 'p-1',
        'client_uuid': 'p-1',
        'student_id': 's-1',
        'paid_at': '2026-09-25T13:11:41Z',
        'receipt_id': receiptId,
        'cancelled_at': cancelledAt,
        'sync_status': 'SYNCED',
      });

  Future<void> seedLocalDocument({
    required String number,
    required String status,
    String? provisionalNumber,
  }) => school.insert('generated_documents', {
    'id': 'gd-1',
    'doc_domain': 'PAYMENT',
    'payment_id': 'p-1',
    'doc_type': 'RC',
    'number': number,
    'provisional_number': provisionalNumber,
    'status': status,
  });

  test('le numéro scellé local passe en premier', () async {
    await seedPayment(receiptId: 'doc-1');
    await seedLocalDocument(
      number: 'CF-RC-2627-000263',
      status: 'DEFINITIVE',
      provisionalNumber: 'PROV-0CB02AF9',
    );

    final receipt = await resolver.resolve('p-1');

    expect(receipt.number, 'CF-RC-2627-000263');
    expect(receipt.status, PaymentReceiptStatus.definitive);
    expect(receipt.documentId, 'doc-1');
  });

  // Le cas TSHIALA Gloredi : versement encaissé sur l'autre caisse, aucune
  // ligne locale, reçu seulement appris par le pull des pièces (sans PDF).
  test('un versement d ailleurs lit son numéro dans le cache', () async {
    await seedPayment(receiptId: 'doc-9');
    await cache.upsert(_knownOnly(documentNumber: 'CF-RC-2627-000279'));

    final receipt = await resolver.resolve('p-1');

    expect(receipt.number, 'CF-RC-2627-000279');
    expect(receipt.isDefinitive, isTrue);
    expect(receipt.cacheEntry?.hasBytes, isFalse);
  });

  test('inconnu du cache : aucun numéro, mais l identifiant reste', () async {
    await seedPayment(receiptId: 'doc-9');

    final receipt = await resolver.resolve('p-1');

    expect(receipt.number, isNull);
    expect(receipt.status, PaymentReceiptStatus.unknown);
    expect(receipt.documentId, 'doc-9');
  });

  test('un encaissement de ce poste pas encore acquitté reste PROV', () async {
    await seedPayment();
    await seedLocalDocument(number: 'PROV-0CB02AF9', status: 'PROVISIONAL');

    final receipt = await resolver.resolve('p-1');

    expect(receipt.number, 'PROV-0CB02AF9');
    expect(receipt.status, PaymentReceiptStatus.provisional);
  });

  test('un reçu annulé connu du seul pull est vu annulé', () async {
    await seedPayment(receiptId: 'doc-9');
    await cache.upsert(
      _knownOnly(
        cancelledAt: 1790400000000,
        cancellationReason: 'Erreur de montant',
      ),
    );

    final receipt = await resolver.resolve('p-1');

    expect(receipt.isReceiptCancelled, isTrue);
    expect(receipt.isCancelled, isTrue);
  });

  test('un versement annulé par le serveur est vu annulé', () async {
    await seedPayment(receiptId: 'doc-9', cancelledAt: 1790400000000);

    final receipt = await resolver.resolve('p-1');

    expect(receipt.isPaymentCancelled, isTrue);
    expect(receipt.isCancelled, isTrue);
  });

  test('sans droit sur les pièces, le cache n est pas lu', () async {
    access.entitled = false;
    await seedPayment(receiptId: 'doc-9');
    await cache.upsert(cacheEntry(id: 'c-9', documentId: 'doc-9'));

    final receipt = await resolver.resolve('p-1');

    expect(receipt.number, isNull);
    expect(receipt.cacheEntry, isNull);
  });

  test('un versement introuvable rend un reçu inconnu', () async {
    final receipt = await resolver.resolve('p-absent');

    expect(receipt.status, PaymentReceiptStatus.unknown);
    expect(receipt.isCancelled, isFalse);
  });

  test('le repli court prend les huit premiers caractères', () {
    expect(
      PaymentReceiptReference.shortFallback(
        'edbbdddf-42a3-410e-bb13-8733d9ec2896',
      ),
      'EDBBDDDF',
    );
  });
}
