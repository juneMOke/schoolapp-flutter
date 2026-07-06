import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

void main() {
  group('CreatePaymentRequest', () {
    final tRequest = const CreatePaymentRequest(
      id: 'pay1',
      studentId: 's1',
      academicYearId: 'ay-1',
      amountInCents: 30000,
      currency: 'USD',
      method: 'CASH',
      paidAt: '2026-07-06T10:00:00Z',
      payerFirstName: 'Sarah',
      payerLastName: 'Moke',
      allocations: [
        PaymentAllocationRequest(
          id: 'a1',
          studentChargeId: 'c1',
          feeCode: 'TUITION',
          studentChargeLabel: 'Scolarité',
          amountInCents: 30000,
          currency: 'USD',
        ),
      ],
    );

    test(
      'toJson : centimes int, id honoré + clientUuid enrichi, paidAt ISO',
      () {
        final json = tRequest.toJson();
        expect(json['id'], 'pay1');
        expect(json['clientUuid'], 'pay1');
        expect(json['amountInCents'], isA<int>());
        expect(json['paidAt'], '2026-07-06T10:00:00Z');
        expect(json['allocations'][0]['feeCode'], 'TUITION');
        expect(json['allocations'][0]['clientUuid'], 'a1');
      },
    );

    test('round-trip fromJson', () {
      final restored = CreatePaymentRequest.fromJson(tRequest.toJson());
      expect(restored.id, 'pay1');
      expect(restored.amountInCents, 30000);
      expect(restored.allocations.single.studentChargeId, 'c1');
    });
  });

  group('PaymentCommitAck.fromJson', () {
    test('parse remap allocation + soldes autoritaires + overpayment', () {
      final ack = PaymentCommitAck.fromJson({
        'paymentId': 'pay1',
        'payment': {'id': 'pay1', 'status': 'CONFIRMED', 'paidAt': 'x'},
        'allocations': [
          {'id': 'a1', 'studentChargeId': 'real-charge'},
        ],
        'updatedCharges': [
          {
            'id': 'real-charge',
            'amountPaidInCents': 30000,
            'status': 'PARTIAL',
          },
        ],
        'overpayment': {'amountInCents': 500, 'currency': 'USD'},
      });

      expect(ack.paymentId, 'pay1');
      expect(ack.allocations.single.studentChargeId, 'real-charge');
      expect(ack.updatedCharges.single.amountPaidInCents, 30000);
      expect(ack.updatedCharges.single.status, 'PARTIAL');
      expect(ack.overpayment!.amountInCents, 500);
    });

    test('paymentId dérivé de payment.id si absent au niveau racine', () {
      final ack = PaymentCommitAck.fromJson({
        'payment': {'id': 'pay-2', 'status': 'CONFIRMED'},
      });
      expect(ack.paymentId, 'pay-2');
    });
  });
}
