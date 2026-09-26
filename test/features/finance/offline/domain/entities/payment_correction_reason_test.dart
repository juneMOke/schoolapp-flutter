import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';

void main() {
  group('motifs par geste (R6)', () {
    test('annuler propose les motifs d annulation et « Autre »', () {
      expect(
        PaymentCorrectionReason.forGesture(PaymentCorrectionGesture.cancel),
        [
          PaymentCorrectionReason.refunded,
          PaymentCorrectionReason.duplicate,
          PaymentCorrectionReason.wrongDevice,
          PaymentCorrectionReason.other,
        ],
      );
    });

    test('corriger propose les motifs de remplacement et « Autre »', () {
      expect(
        PaymentCorrectionReason.forGesture(PaymentCorrectionGesture.replace),
        [
          PaymentCorrectionReason.wrongAmount,
          PaymentCorrectionReason.wrongAllocation,
          PaymentCorrectionReason.wrongStudent,
          PaymentCorrectionReason.other,
        ],
      );
    });

    test('seul « Autre » exige une précision', () {
      expect(PaymentCorrectionReason.values.where((r) => r.requiresDetail), [
        PaymentCorrectionReason.other,
      ]);
    });

    test('le code du fil se relit', () {
      for (final reason in PaymentCorrectionReason.values) {
        expect(PaymentCorrectionReason.fromCode(reason.code), reason);
      }
      expect(PaymentCorrectionReason.fromCode('INCONNU'), isNull);
    });
  });

  group('pull (B5)', () {
    Map<String, dynamic> json({String? replaces}) => {
      'id': 'p-2',
      'studentId': 's-1',
      'paidAt': '2026-09-25T13:11:41Z',
      'replacesPaymentId': ?replaces,
    };

    test('le lien de remplacement descend jusqu à la ligne locale', () {
      final local = PaymentDto.fromJson(json(replaces: 'p-1')).toLocalModel(1);

      expect(local.replacesPaymentId, 'p-1');
      expect(local.toPullPatch()['replaces_payment_id'], 'p-1');
    });

    // Un serveur d'avant B5 n'envoie pas le champ : le patch ne doit pas
    // effacer un lien posé par le geste de ce poste.
    test('absent du delta, il n efface rien', () {
      final local = PaymentDto.fromJson(json()).toLocalModel(1);

      expect(local.toPullPatch().containsKey('replaces_payment_id'), isFalse);
    });
  });
}
