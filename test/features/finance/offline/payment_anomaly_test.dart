import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_ack_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_anomaly_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart'
    show StudentChargeDto;
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_push_response_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_anomaly.dart';

import '../../offline_full_db.dart';

PaymentAggregateResponse _ack({
  OverpaymentSignal? overpayment,
  List<StudentChargeDto> charges = const [],
}) => PaymentAggregateResponse(
  payment: const AckPaymentRef(id: 'p-1', receiptId: 'r-1'),
  charges: charges,
  overpayment: overpayment,
);

void main() {
  late Database db;
  late FinancePaymentAckDao ackDao;
  late PaymentAnomalyDao anomalyDao;

  setUp(() async {
    db = await openFullOfflineDb();
    ackDao = FinancePaymentAckDao(db);
    anomalyDao = PaymentAnomalyDao(db);

    await db.insert('payments', {
      'id': 'p-1',
      'client_uuid': 'p-1',
      'student_id': 's-1',
      'academic_year_id': 'y-1',
      'amount_in_cents': 150000,
      'currency': 'CDF',
      'method': 'CASH',
      'paid_at': '2026-08-04T14:07:00.000',
      'payer_first_name': 'Papa',
      'payer_last_name': 'Mbala',
      'cashier_first_name': 'Jean',
      'cashier_last_name': 'Kabeya',
      'device_id': 'device-abc',
      'sync_status': 'PENDING_SYNC',
      'updated_at': 0,
    });
  });

  tearDown(() async => db.close());

  test('aucune anomalie sur un ACK nominal', () async {
    await ackDao.applyPaymentAck(_ack(), nowMs: 100);

    expect(await anomalyDao.openCount(), 0);
  });

  test('aucune anomalie quand le signal existe mais ne détecte rien', () async {
    await ackDao.applyPaymentAck(
      _ack(overpayment: const OverpaymentSignal(detected: false)),
      nowMs: 100,
    );

    expect(await anomalyDao.openCount(), 0);
  });

  // Le signal était désérialisé et consommé par personne : un trop-perçu
  // passait totalement inaperçu.
  test('ouvre une anomalie sur un trop-perçu détecté', () async {
    await ackDao.applyPaymentAck(
      _ack(
        overpayment: const OverpaymentSignal(
          detected: true,
          excessInCents: 25000,
          currency: 'CDF',
          feeCode: 'TUITION',
          reason: 'Montant supérieur au reste dû',
        ),
      ),
      nowMs: 100,
    );

    final anomalies = await anomalyDao.openAnomalies();
    expect(anomalies, hasLength(1));

    final anomaly = anomalies.single;
    expect(anomaly.paymentId, 'p-1');
    expect(anomaly.kind, PaymentAnomalyKind.overpayment);
    expect(anomaly.excessInCents, 25000);
    expect(anomaly.isOpen, isTrue);
  });

  // RG-012-15/16 : l'alerte doit nommer l'élève, le caissier et la tablette,
  // sans dépendre d'une jointure qui pourrait ne plus résoudre plus tard.
  test('recopie élève, caissier et appareil depuis le paiement', () async {
    await ackDao.applyPaymentAck(
      _ack(
        overpayment: const OverpaymentSignal(detected: true, excessInCents: 1),
      ),
      nowMs: 100,
    );

    final anomaly = (await anomalyDao.openAnomalies()).single;
    expect(anomaly.studentId, 's-1');
    expect(anomaly.cashierFullName, 'Jean Kabeya');
    expect(anomaly.deviceId, 'device-abc');
  });

  // Le rejeu d'un ACK est le cas NORMAL (200 idempotent) : il ne doit ni
  // empiler des doublons, ni surtout rouvrir une anomalie déjà traitée.
  test('un rejeu de l ACK n empile pas de doublon', () async {
    final ack = _ack(
      overpayment: const OverpaymentSignal(detected: true, excessInCents: 5000),
    );

    await ackDao.applyPaymentAck(ack, nowMs: 100);
    await ackDao.applyPaymentAck(ack, nowMs: 200);

    expect(await anomalyDao.openCount(), 1);
  });

  test('un rejeu ne rouvre pas une anomalie déjà traitée', () async {
    final ack = _ack(
      overpayment: const OverpaymentSignal(detected: true, excessInCents: 5000),
    );
    await ackDao.applyPaymentAck(ack, nowMs: 100);

    final anomaly = (await anomalyDao.openAnomalies()).single;
    await anomalyDao.acknowledge(
      id: anomaly.id,
      acknowledgedBy: 'u-9',
      nowMs: 150,
    );
    expect(await anomalyDao.openCount(), 0);

    await ackDao.applyPaymentAck(ack, nowMs: 200);

    expect(await anomalyDao.openCount(), 0);
  });

  // L'accusé est le SEUL chemin qui éteint une anomalie.
  test(
    'l accusé de traitement éteint l anomalie et nomme son auteur',
    () async {
      await ackDao.applyPaymentAck(
        _ack(
          overpayment: const OverpaymentSignal(
            detected: true,
            excessInCents: 1,
          ),
        ),
        nowMs: 100,
      );
      final anomaly = (await anomalyDao.openAnomalies()).single;

      await anomalyDao.acknowledge(
        id: anomaly.id,
        acknowledgedBy: 'u-9',
        nowMs: 500,
      );

      expect(await anomalyDao.openAnomalies(), isEmpty);
      final rows = await db.query('payment_anomalies');
      expect(rows.single['acknowledged_by'], 'u-9');
      expect(rows.single['acknowledged_at'], 500);
    },
  );

  test(
    'un accusé sur une anomalie déjà traitée ne réécrit pas l auteur',
    () async {
      await ackDao.applyPaymentAck(
        _ack(
          overpayment: const OverpaymentSignal(
            detected: true,
            excessInCents: 1,
          ),
        ),
        nowMs: 100,
      );
      final anomaly = (await anomalyDao.openAnomalies()).single;

      await anomalyDao.acknowledge(
        id: anomaly.id,
        acknowledgedBy: 'u-9',
        nowMs: 500,
      );
      await anomalyDao.acknowledge(
        id: anomaly.id,
        acknowledgedBy: 'u-42',
        nowMs: 900,
      );

      final rows = await db.query('payment_anomalies');
      expect(rows.single['acknowledged_by'], 'u-9');
    },
  );

  // Un motif inconnu d'un serveur plus récent s'affiche quand même : mieux vaut
  // une alerte générique qu'une anomalie invisible.
  test('un motif inconnu retombe sur unknown sans être perdu', () async {
    await db.insert('payment_anomalies', {
      'id': 'a-x',
      'payment_id': 'p-1',
      'kind': 'SOMETHING_NEW',
      'detected_at': 10,
    });

    final anomaly = (await anomalyDao.openAnomalies()).single;
    expect(anomaly.kind, PaymentAnomalyKind.unknown);
  });
}
