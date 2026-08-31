import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

void main() {
  group(
    'PaymentAggregateRequest — openapi_billing_sync §PaymentAggregateRequest',
    () {
      final tRequest = PaymentAggregateRequest(
        payment: PaymentInput(
          id: 'pay1',
          studentId: 's1',
          academicYearId: 'ay-1',
          // Égal à la somme des imputations, devise par devise — c'est ce que
          // le serveur vérifie (`ALLOCATION_SUM_MISMATCH`).
          amounts: MoneyBag.of(const [Money(30000, 'USD')]),
          method: 'CASH',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'Sarah',
          payerLastName: 'Moke',
        ),
        allocations: [
          const PaymentAllocationInput(
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
        'toJson : forme IMBRIQUÉE {payment, allocations} (contrat 1.1.0)',
        () {
          final json = tRequest.toJson();

          expect(json.keys, containsAll(<String>['payment', 'allocations']));
          final payment = json['payment'] as Map<String, dynamic>;
          expect(
            payment['id'],
            'pay1',
          ); // uuid client honoré = clé d'idempotence
          expect(payment['studentId'], 's1');
          // `amounts[]` : une entrée par devise, centimes entiers — jamais un
          // flottant, et jamais un scalaire qui prétendrait résumer deux unités.
          final amounts = payment['amounts'] as List<dynamic>;
          expect(amounts, isNotEmpty);
          expect(
            (amounts.first as Map<String, dynamic>)['amountInCents'],
            isA<int>(),
          );
          expect(payment['paidAt'], '2026-07-06T10:00:00Z');
          // Les champs de paiement ne sont plus à plat à la racine.
          expect(json['id'], isNull);
          expect(json['studentId'], isNull);
        },
      );

      test('toJson : method absent → défaut CASH', () {
        final sansMethode = PaymentInput(
          id: 'p',
          studentId: 's',
          amounts: MoneyBag.of(const [Money(1, 'USD')]),
          paidAt: 'x',
        );
        expect(sansMethode.toJson()['method'], 'CASH');
      });

      test(
        'toJson : allocations portent le feeCode (clé de remap serveur)',
        () {
          final allocs = tRequest.toJson()['allocations'] as List<dynamic>;
          final first = allocs.single as Map<String, dynamic>;
          expect(first['feeCode'], 'TUITION');
          expect(first['studentChargeId'], 'c1');
          expect(first['studentChargeLabel'], 'Scolarité');
          expect(first['amountInCents'], 30000);
        },
      );

      test('round-trip fromJson (payload outbox relu après coupure)', () {
        final restored = PaymentAggregateRequest.fromJson(tRequest.toJson());

        expect(restored.payment.id, 'pay1');
        expect(restored.payment.studentId, 's1');
        expect(restored.payment.amounts, tRequest.payment.amounts);
        expect(restored.allocations.single.studentChargeId, 'c1');
        expect(restored.allocations.single.feeCode, 'TUITION');
      });

      test(
        'payload LEGACY à plat (outbox écrit par une version antérieure) : relu '
        'sans perte — le cash encaissé hors-ligne avant la mise à jour remonte',
        () {
          // Forme exacte de l'ancien `CreatePaymentRequest.toJson()`, telle
          // qu'elle dort encore dans `outbox.payload` d'une tablette mise à jour
          // hors-ligne (clientUuid inclus, ignoré par le nouveau contrat).
          final legacy = <String, dynamic>{
            'id': 'pay-legacy',
            'clientUuid': 'pay-legacy',
            'studentId': 's1',
            'academicYearId': 'ay-1',
            'amountInCents': 30000,
            'currency': 'USD',
            'method': 'CASH',
            'paidAt': '2026-07-06T10:00:00Z',
            'payerFirstName': 'Sarah',
            'payerLastName': 'Moke',
            'payerMiddleName': null,
            'allocations': [
              {
                'id': 'a1',
                'clientUuid': 'a1',
                'studentChargeId': 'c1',
                'feeCode': 'TUITION',
                'studentChargeLabel': 'Scolarité',
                'amountInCents': 30000,
                'currency': 'USD',
              },
            ],
          };

          final restored = PaymentAggregateRequest.fromJson(legacy);

          expect(restored.payment.id, 'pay-legacy');
          expect(restored.payment.studentId, 's1');
          // La forme SCALAIRE est relue en sac : un versement figé dans
          // l'outbox par la version précédente doit remonter, sinon le cash
          // encaissé — reçu déjà imprimé — ne repart jamais.
          expect(
            restored.payment.amounts,
            MoneyBag.of(const [Money(30000, 'USD')]),
          );
          expect(restored.payment.payerFirstName, 'Sarah');
          expect(restored.allocations.single.id, 'a1');
          expect(restored.allocations.single.feeCode, 'TUITION');
          // Repoussé dans la forme imbriquée du contrat 1.1.0.
          expect((restored.toJson()['payment'] as Map)['id'], 'pay-legacy');
        },
      );

      test('studentChargeId null (créance pas encore matérialisée) survit au '
          'round-trip → le serveur remappera par studentId + feeCode', () {
        final avance = PaymentAggregateRequest(
          payment: PaymentInput(
            id: 'p',
            studentId: 's',
            amounts: MoneyBag.of(const [Money(500, 'USD')]),
            paidAt: 'x',
          ),
          allocations: [
            const PaymentAllocationInput(
              id: 'a',
              feeCode: 'INSCRIPTION',
              studentChargeLabel: 'Inscription',
              amountInCents: 500,
              currency: 'USD',
            ),
          ],
        );
        final restored = PaymentAggregateRequest.fromJson(avance.toJson());
        expect(restored.allocations.single.studentChargeId, isNull);
      });
    },
  );

  group(
    'PaymentAggregateResponse — openapi_billing_sync §PaymentAggregateResponse',
    () {
      test('parse remap + créances autoritaires + documents + overpayment', () {
        final ack = PaymentAggregateResponse.fromJson({
          'payment': {'id': 'pay1', 'receiptId': 'rec-1'},
          'allocations': [
            {
              'providedId': 'a1',
              'canonicalId': 'a1',
              'providedStudentChargeId': 'prov-1',
              'canonicalStudentChargeId': 'real-charge',
              'feeCode': 'TUITION',
            },
          ],
          'charges': [
            {
              'id': 'real-charge',
              'studentId': 's1',
              'feeCode': 'TUITION',
              'label': 'Scolarité',
              'expectedAmountInCents': 50000,
              'amountPaidInCents': 30000,
              'currency': 'USD',
              'status': 'PARTIAL',
              'serverUpdatedAt': '2026-07-16T10:00:00Z',
            },
          ],
          'documents': [
            {
              'type': 'PAYMENT_RECEIPT',
              'documentNumber': 'ETL-RP-0001',
              'status': 'DEFINITIVE',
            },
          ],
          'overpayment': {
            'detected': true,
            'excessInCents': 500,
            'currency': 'USD',
            'feeCode': 'TUITION',
            'reason': 'amountPaid > expected',
          },
        });

        expect(ack.paymentId, 'pay1');
        expect(ack.payment.receiptId, 'rec-1');

        final remap = ack.allocations.single;
        expect(remap.providedId, 'a1');
        expect(remap.canonicalStudentChargeId, 'real-charge');
        expect(remap.providedStudentChargeId, 'prov-1');
        expect(remap.feeCode, 'TUITION'); // porté par la réponse

        // `charges` = le schéma StudentCharge du pull, réutilisé tel quel.
        expect(ack.charges.single.amountPaidInCents, 30000);
        expect(ack.charges.single.expectedAmountInCents, 50000);
        expect(ack.charges.single.status, 'PARTIAL');

        expect(ack.documents.single.documentNumber, 'ETL-RP-0001');
        expect(ack.documents.single.localDocType, 'RC');

        expect(ack.overpayment!.detected, isTrue);
        expect(ack.overpayment!.excessInCents, 500);
        expect(ack.overpayment!.feeCode, 'TUITION');
      });

      test(
        'documents vide (scellement best-effort en échec) : ACK valide, jamais un '
        'échec d\'encaissement',
        () {
          final ack = PaymentAggregateResponse.fromJson({
            'payment': {'id': 'pay-2'},
            'charges': const <dynamic>[],
          });

          expect(ack.paymentId, 'pay-2');
          expect(ack.payment.receiptId, isNull);
          expect(ack.documents, isEmpty);
          expect(ack.allocations, isEmpty);
          expect(ack.overpayment, isNull);
        },
      );

      test('overpayment non détecté → detected false', () {
        final ack = PaymentAggregateResponse.fromJson({
          'payment': {'id': 'p'},
          'overpayment': {'detected': false},
        });
        expect(ack.overpayment!.detected, isFalse);
        expect(ack.overpayment!.excessInCents, isNull);
      });

      test(
        'type de document inconnu → rendu tel quel (aucun UPDATE ne matche)',
        () {
          const doc = GeneratedDocumentDto(
            type: 'SOMETHING_NEW',
            documentNumber: 'X',
            status: 'DEFINITIVE',
          );
          expect(doc.localDocType, 'SOMETHING_NEW');
          expect(
            const GeneratedDocumentDto(
              type: 'PAYMENT_NOTICE',
              documentNumber: 'X',
              status: 'DEFINITIVE',
            ).localDocType,
            'NP',
          );
        },
      );
    },
  );
}
