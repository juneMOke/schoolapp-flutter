import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/data/mappers/local_finance_online_mappers.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

void main() {
  group('LocalStudentCharge → StudentCharge', () {
    test('porte le reste COMPOSÉ (miroir + pending) et le flag provisoire', () {
      const local = LocalStudentCharge(
        id: 'c1',
        studentId: 's1',
        feeCode: 'TUITION',
        label: 'Scolarité',
        expectedAmountInCents: 100000,
        amountPaidInCents: 40000, // miroir serveur
        amountPaidPendingInCents: 30000, // encaissé localement, non remonté
        currency: 'USD',
        status: StudentChargeStatus.partial,
        syncState: SyncState.provisional,
      );

      final online = local.toOnlineEntity();
      expect(online.amountPaidInCents, 40000.0, reason: 'miroir serveur seul');
      expect(online.amountPaidPendingInCents, 30000.0);
      expect(online.paidTotalInCents, 70000.0);
      expect(online.remainingInCents, 30000.0, reason: 'reste composé');
      expect(online.isProvisional, isTrue);
      expect(online.status, StudentChargeStatus.partial);
    });

    test('reste borné à 0 si trop-perçu (versement > dû)', () {
      const local = LocalStudentCharge(
        id: 'c1',
        studentId: 's1',
        feeCode: 'TUITION',
        label: 'Scolarité',
        expectedAmountInCents: 100000,
        amountPaidInCents: 0,
        amountPaidPendingInCents: 120000,
        currency: 'USD',
        status: StudentChargeStatus.paid,
      );
      expect(local.toOnlineEntity().remainingInCents, 0.0);
    });
  });

  group('LocalPayment → Payment', () {
    mapPayment(SyncState s) => LocalPayment(
      id: 'p1',
      clientUuid: 'p1',
      studentId: 's1',
      amounts: MoneyBag.of(const [Money(30000, 'USD')]),
      method: PaymentMethod.cash,
      paidAt: '2026-07-06T10:00:00Z',
      payerFirstName: 'Sarah',
      payerLastName: 'Moke',
      syncState: s,
    ).toOnlineEntity();

    test('PENDING_SYNC / SYNC_ERROR → isPendingSync=true ; SYNCED → false', () {
      expect(mapPayment(SyncState.pendingSync).isPendingSync, isTrue);
      expect(mapPayment(SyncState.syncError).isPendingSync, isTrue);
      expect(mapPayment(SyncState.synced).isPendingSync, isFalse);
    });

    test('paidAt ISO parsé en DateTime', () {
      expect(
        mapPayment(SyncState.synced).paidAt,
        DateTime.parse('2026-07-06T10:00:00Z'),
      );
    });
  });

  group('LocalPaymentAllocation → PaymentAllocation', () {
    test('allocation d\'avance (chargeId null) → chaîne vide', () {
      const local = LocalPaymentAllocation(
        id: 'a1',
        paymentId: 'p1',
        studentChargeId: null,
        feeCode: 'TUITION',
        studentChargeLabel: 'Scolarité',
        amountInCents: 30000,
        currency: 'USD',
      );
      expect(local.toOnlineEntity().studentChargeId, '');
    });
  });
}
