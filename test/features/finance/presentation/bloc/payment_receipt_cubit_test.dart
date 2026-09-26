import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_receipt_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart';

class _MockPaymentReceiptResolver extends Mock
    implements PaymentReceiptResolver {}

/// Un reçu appris par le pull des pièces : métadonnées seules, sans PDF.
EditiqueCacheEntry _known({int? cancelledAt, String? reason}) =>
    EditiqueCacheEntry(
      id: 'c-1',
      documentId: 'doc-1',
      documentNumber: 'CF-RC-2627-000279',
      docType: 'RC',
      schoolId: 'school-1',
      ownerUid: 'u-1',
      sizeBytes: 0,
      cancelledAt: cancelledAt,
      cancellationReason: reason,
      createdAt: 1000,
      lastAccessedAt: 1000,
    );

void main() {
  late _MockPaymentReceiptResolver resolver;

  setUp(() => resolver = _MockPaymentReceiptResolver());

  void answer(PaymentReceiptReference receipt) =>
      when(() => resolver.resolve(any())).thenAnswer((_) async => receipt);

  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'expose un numéro définitif tel quel',
    setUp: () => answer(
      const PaymentReceiptReference(
        number: 'ETL-RC-2526-000212',
        status: PaymentReceiptStatus.definitive,
      ),
    ),
    build: () => PaymentReceiptCubit(resolver),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.number, 'number', 'ETL-RC-2526-000212')
          .having((s) => s.isDefinitive, 'isDefinitive', isTrue)
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isTrue),
    ],
  );

  // Un `PROV-…` local n'a aucune valeur officielle : il est porté par l'état
  // mais `hasDefinitiveNumber` interdit de l'afficher comme un numéro de pièce.
  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'marque un numéro provisoire comme non affichable',
    setUp: () => answer(
      const PaymentReceiptReference(
        number: 'PROV-ABCD1234',
        status: PaymentReceiptStatus.provisional,
      ),
    ),
    build: () => PaymentReceiptCubit(resolver),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.isDefinitive, 'isDefinitive', isFalse)
          .having((s) => s.hasProvisionalNumber, 'hasProvisionalNumber', isTrue)
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isFalse),
    ],
  );

  // Régression : un versement encaissé sur un AUTRE poste et inconnu du cache
  // ne doit pas être annoncé « en attente de synchronisation ».
  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'n annonce aucune attente quand aucun numéro n est connu',
    setUp: () => answer(const PaymentReceiptReference(documentId: 'doc-1')),
    build: () => PaymentReceiptCubit(resolver),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.loaded, 'loaded', isTrue)
          .having((s) => s.number, 'number', isNull)
          .having((s) => s.documentId, 'documentId', 'doc-1')
          .having(
            (s) => s.hasProvisionalNumber,
            'hasProvisionalNumber',
            isFalse,
          )
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isFalse),
    ],
  );

  test('un numéro blanc ne compte pas comme définitif', () {
    const state = PaymentReceiptState(loaded: true, number: '   ');
    expect(state.hasDefinitiveNumber, isFalse);
  });

  test('n annonce aucune attente avant le chargement', () {
    const state = PaymentReceiptState();

    expect(state.hasProvisionalNumber, isFalse);
    expect(state.hasDefinitiveNumber, isFalse);
  });

  // Un reçu retiré doit atteindre l'état même sans PDF sur cette tablette :
  // c'est lui qui porte le motif que le guichet affichera.
  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'porte jusqu à l état le reçu retiré, connu du seul pull',
    setUp: () => answer(
      PaymentReceiptReference(
        number: 'CF-RC-2627-000279',
        status: PaymentReceiptStatus.definitive,
        documentId: 'doc-1',
        cacheEntry: _known(cancelledAt: 1786013000000, reason: 'Erreur'),
      ),
    ),
    build: () => PaymentReceiptCubit(resolver),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.cached?.isCancelled, 'cached.isCancelled', isTrue)
          .having(
            (s) => s.cached?.cancellationReason,
            'cancellationReason',
            'Erreur',
          )
          .having((s) => s.cached?.hasBytes, 'cached.hasBytes', isFalse),
    ],
  );

  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'porte l annulation du versement par le serveur',
    setUp: () => answer(
      const PaymentReceiptReference(
        documentId: 'doc-1',
        paymentCancelledAt: 1786013000000,
      ),
    ),
    build: () => PaymentReceiptCubit(resolver),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>().having(
        (s) => s.paymentCancelled,
        'paymentCancelled',
        isTrue,
      ),
    ],
  );

  // R3 de T0 : un reçu connu du cache, annulé ou non, ne s'ÉMET jamais —
  // l'émission rescellerait la pièce et consommerait un numéro.
  group('aucune émission sur un reçu connu', () {
    for (final cancelledAt in [null, 1786013000000]) {
      final label = cancelledAt == null ? 'en vigueur' : 'annulé';
      blocTest<PaymentReceiptCubit, PaymentReceiptState>(
        'reçu $label connu du cache : restitution',
        setUp: () => answer(
          PaymentReceiptReference(
            number: 'CF-RC-2627-000279',
            status: PaymentReceiptStatus.definitive,
            documentId: 'doc-1',
            cacheEntry: _known(cancelledAt: cancelledAt),
          ),
        ),
        build: () => PaymentReceiptCubit(resolver),
        act: (cubit) => cubit.load('pay-1'),
        verify: (cubit) => expect(
          facturationReceiptGesture(
            cached: cubit.state.cached,
            isPendingSync: false,
            receiptDocumentId: cubit.state.documentId,
          ),
          FacturationReceiptGesture.restitute,
        ),
      );
    }

    blocTest<PaymentReceiptCubit, PaymentReceiptState>(
      'reçu inconnu du cache mais désigné par le versement : restitution',
      setUp: () => answer(const PaymentReceiptReference(documentId: 'doc-1')),
      build: () => PaymentReceiptCubit(resolver),
      act: (cubit) => cubit.load('pay-1'),
      verify: (cubit) => expect(
        facturationReceiptGesture(
          cached: cubit.state.cached,
          isPendingSync: false,
          receiptDocumentId: cubit.state.documentId,
        ),
        FacturationReceiptGesture.restitute,
      ),
    );
  });
}
