import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';

import '../../offline_full_db.dart';

class _SeqIdGenerator extends IdGenerator {
  _SeqIdGenerator() : super(const Uuid());
  int _i = 0;
  @override
  String newId() => 'id-${_i++}';
}

/// Insère une ligne de `generated_documents` directement : ce test porte sur la
/// LECTURE, il ne doit pas dépendre du chemin d'écriture d'un encaissement.
Future<void> _insertDocument(
  Database db, {
  required String id,
  required String paymentId,
  required String number,
  String docDomain = 'PAYMENT',
  String docType = 'RC',
  String status = 'PROVISIONAL',
  int createdAt = 0,
}) {
  return db.insert('generated_documents', <String, Object?>{
    'id': id,
    'doc_domain': docDomain,
    'payment_id': paymentId,
    'student_id': 'stu-1',
    'doc_type': docType,
    'number': number,
    'status': status,
    'created_at': createdAt,
  });
}

void main() {
  late Database db;
  late FinanceLocalDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FinanceLocalDao(db, _SeqIdGenerator());
  });

  tearDown(() async => db.close());

  group('FinanceLocalDao.getPaymentReceipt', () {
    test('rend null quand aucun document n existe pour ce paiement', () async {
      expect(await dao.getPaymentReceipt('pay-inconnu'), isNull);
    });

    test('rend le reçu provisoire écrit à l encaissement', () async {
      await _insertDocument(
        db,
        id: 'doc-1',
        paymentId: 'pay-1',
        number: 'PROV-ABCD1234',
      );

      final receipt = await dao.getPaymentReceipt('pay-1');

      expect(receipt, isNotNull);
      expect(receipt!.number, 'PROV-ABCD1234');
      expect(receipt.isProvisional, isTrue);
    });

    test('rend le numéro définitif une fois scellé', () async {
      await _insertDocument(
        db,
        id: 'doc-1',
        paymentId: 'pay-1',
        number: 'ETL-RC-2526-000212',
        status: 'DEFINITIVE',
      );

      final receipt = await dao.getPaymentReceipt('pay-1');

      expect(receipt!.number, 'ETL-RC-2526-000212');
      expect(receipt.isProvisional, isFalse);
    });

    // La table sert les deux domaines : une attestation d'inscription ne doit
    // jamais être servie comme reçu de paiement.
    test(
      'ignore les documents d un autre domaine ou d un autre type',
      () async {
        await _insertDocument(
          db,
          id: 'doc-ai',
          paymentId: 'pay-1',
          number: 'ETL-AI-2526-000087',
          docDomain: 'ENROLLMENT',
          docType: 'AI',
        );
        await _insertDocument(
          db,
          id: 'doc-np',
          paymentId: 'pay-1',
          number: 'ETL-NP-2526-000004',
          docType: 'NP',
        );

        expect(await dao.getPaymentReceipt('pay-1'), isNull);
      },
    );

    test('ignore le reçu d un autre paiement', () async {
      await _insertDocument(
        db,
        id: 'doc-1',
        paymentId: 'pay-autre',
        number: 'ETL-RC-2526-000001',
      );

      expect(await dao.getPaymentReceipt('pay-1'), isNull);
    });

    test('retient le plus récent si plusieurs lignes coexistent', () async {
      await _insertDocument(
        db,
        id: 'doc-vieux',
        paymentId: 'pay-1',
        number: 'PROV-ABCD1234',
        createdAt: 1000,
      );
      await _insertDocument(
        db,
        id: 'doc-recent',
        paymentId: 'pay-1',
        number: 'ETL-RC-2526-000212',
        status: 'DEFINITIVE',
        createdAt: 2000,
      );

      final receipt = await dao.getPaymentReceipt('pay-1');

      expect(receipt!.number, 'ETL-RC-2526-000212');
    });
  });
}
