import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_in_force_sql.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';

import '../../../../offline_full_db.dart';

/// Les deux prédicats, exercés en SQL réel : c'est leur seule vérité.
void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() async => db.close());

  Future<void> payment(
    String id, {
    String syncStatus = 'SYNCED',
    int? cancelledAt,
  }) => db.insert('payments', {
    'id': id,
    'client_uuid': id,
    'student_id': 's-1',
    'paid_at': '2026-09-25T13:11:41Z',
    'sync_status': syncStatus,
    'cancelled_at': cancelledAt,
  });

  Future<void> correction(String paymentId, PaymentCorrectionStatus status) =>
      db.insert('payment_corrections', {
        'id': 'pc-$paymentId-${status.dbValue}',
        'payment_id': paymentId,
        'student_id': 's-1',
        'reason_code': 'WRONG_AMOUNT',
        'client_cancelled_at': '2026-09-26T09:14:00Z',
        'status': status.dbValue,
        'created_at': 1,
      });

  Future<Set<String>> where(String predicate) async => {
    for (final r in await db.rawQuery(
      'SELECT p.id FROM payments p WHERE $predicate',
    ))
      r['id']! as String,
  };

  group('inForce', () {
    test('un versement sans correction compte', () async {
      await payment('p-1');

      expect(await where(PaymentInForceSql.inForce('p')), {'p-1'});
    });

    test('une annulation du serveur le retire', () async {
      await payment('p-1', cancelledAt: 1);

      expect(await where(PaymentInForceSql.inForce('p')), isEmpty);
    });

    test('une correction en attente, appliquée ou locale le retire', () async {
      await payment('p-pending');
      await payment('p-applied');
      await payment('p-local', syncStatus: 'SYNC_ERROR');
      await correction('p-pending', PaymentCorrectionStatus.pending);
      await correction('p-applied', PaymentCorrectionStatus.applied);
      await correction('p-local', PaymentCorrectionStatus.localOnly);

      expect(await where(PaymentInForceSql.inForce('p')), isEmpty);
    });

    // R3 : un refus n'a rien changé côté serveur, l'origine reprend cours.
    test('une correction refusée le laisse compter', () async {
      await payment('p-1');
      await correction('p-1', PaymentCorrectionStatus.rejected);

      expect(await where(PaymentInForceSql.inForce('p')), {'p-1'});
    });
  });

  group('pendingServerCancellation', () {
    test('vise un versement synchronisé à la correction en attente', () async {
      await payment('p-1');
      await correction('p-1', PaymentCorrectionStatus.pending);

      expect(await where(PaymentInForceSql.pendingServerCancellation('p')), {
        'p-1',
      });
    });

    // Un versement pas encore remonté n'est pas dans les créances du
    // serveur : il n'y a rien à lui retrancher, il suffit de ne plus
    // l'ajouter (c'est le rôle de `inForce`).
    test('ignore un versement pas encore synchronisé', () async {
      await payment('p-1', syncStatus: 'PENDING_SYNC');
      await correction('p-1', PaymentCorrectionStatus.pending);

      expect(
        await where(PaymentInForceSql.pendingServerCancellation('p')),
        isEmpty,
      );
    });

    // Le cas de la réponse perdue : le pull a déjà ramené l'annulation et les
    // créances recalculées. Retrancher encore compterait deux fois.
    test('s éteint dès que l annulation du serveur est arrivée', () async {
      await payment('p-1', cancelledAt: 1);
      await correction('p-1', PaymentCorrectionStatus.pending);

      expect(
        await where(PaymentInForceSql.pendingServerCancellation('p')),
        isEmpty,
      );
    });

    test('ne vise ni un refus ni une correction appliquée', () async {
      await payment('p-rejected');
      await payment('p-applied');
      await correction('p-rejected', PaymentCorrectionStatus.rejected);
      await correction('p-applied', PaymentCorrectionStatus.applied);

      expect(
        await where(PaymentInForceSql.pendingServerCancellation('p')),
        isEmpty,
      );
    });
  });
}
