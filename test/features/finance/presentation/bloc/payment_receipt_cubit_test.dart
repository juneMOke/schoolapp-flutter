import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/find_cached_document_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payment_receipt_document_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_receipt_cubit.dart';

class MockGetPaymentReceiptDocumentUseCase extends Mock
    implements GetPaymentReceiptDocumentUseCase {}

LocalGeneratedDocument _document({
  required String number,
  required String status,
}) => LocalGeneratedDocument(
  id: 'doc-1',
  docDomain: 'PAYMENT',
  paymentId: 'pay-1',
  docType: 'RC',
  number: number,
  status: status,
);

class _MockFindCachedDocumentUseCase extends Mock
    implements FindCachedDocumentUseCase {}

void main() {
  final cachedUseCase = _MockFindCachedDocumentUseCase();
  setUp(() {
    // Aucune copie locale par défaut : le cubit se comporte comme avant le
    // cache de restitution.
    when(
      () => cachedUseCase(
        documentId: any(named: 'documentId'),
        documentNumber: any(named: 'documentNumber'),
      ),
    ).thenAnswer((_) async => null);
  });

  late MockGetPaymentReceiptDocumentUseCase useCase;

  setUp(() => useCase = MockGetPaymentReceiptDocumentUseCase());

  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'expose un numéro définitif tel quel',
    setUp: () => when(() => useCase(any())).thenAnswer(
      (_) async =>
          _document(number: 'ETL-RC-2526-000212', status: 'DEFINITIVE'),
    ),
    build: () => PaymentReceiptCubit(useCase, cachedUseCase),
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
    setUp: () => when(() => useCase(any())).thenAnswer(
      (_) async => _document(number: 'PROV-ABCD1234', status: 'PROVISIONAL'),
    ),
    build: () => PaymentReceiptCubit(useCase, cachedUseCase),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.isDefinitive, 'isDefinitive', isFalse)
          .having((s) => s.hasProvisionalNumber, 'hasProvisionalNumber', isTrue)
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isFalse),
    ],
  );

  // Régression : le prédicat doit être une affirmation POSITIVE. Avec l'ancien
  // `!isProvisional`, tout statut hors des deux connus rendait `true` et faisait
  // passer un `PROV-…` pour un numéro qui fait foi.
  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'traite un statut inconnu comme non définitif',
    setUp: () => when(() => useCase(any())).thenAnswer(
      (_) async => _document(number: 'PROV-ABCD1234', status: 'REJECTED'),
    ),
    build: () => PaymentReceiptCubit(useCase, cachedUseCase),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.isDefinitive, 'isDefinitive', isFalse)
          .having((s) => s.hasProvisionalNumber, 'hasProvisionalNumber', isTrue)
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isFalse),
    ],
  );

  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'reste neutre quand aucun reçu local n existe',
    setUp: () => when(() => useCase(any())).thenAnswer((_) async => null),
    build: () => PaymentReceiptCubit(useCase, cachedUseCase),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.loaded, 'loaded', isTrue)
          .having((s) => s.number, 'number', isNull)
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isFalse),
    ],
  );

  test('un numéro blanc ne compte pas comme définitif', () {
    const state = PaymentReceiptState(loaded: true, number: '   ');
    expect(state.hasDefinitiveNumber, isFalse);
  });

  // Régression : un versement encaissé sur un AUTRE poste et descendu par pull
  // n'a jamais eu de ligne `generated_documents` locale. Le déduire d'un
  // `!isDefinitive` le ferait annoncer « en attente de synchronisation » alors
  // qu'il est parfaitement synchronisé.
  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'n annonce aucune attente quand aucun reçu local n existe',
    setUp: () => when(() => useCase(any())).thenAnswer((_) async => null),
    build: () => PaymentReceiptCubit(useCase, cachedUseCase),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.loaded, 'loaded', isTrue)
          .having(
            (s) => s.hasProvisionalNumber,
            'hasProvisionalNumber',
            isFalse,
          )
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isFalse),
    ],
  );

  test('n annonce aucune attente avant le chargement', () {
    const state = PaymentReceiptState();

    expect(state.hasProvisionalNumber, isFalse);
    expect(state.hasDefinitiveNumber, isFalse);
  });

  // Un reçu que l'établissement a retiré doit atteindre l'état : c'est lui qui
  // porte le motif que le guichet affichera. Le filtrer en chemin rendrait le
  // retrait invisible ici, et le numéro s'afficherait comme s'il tenait
  // toujours.
  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'porte jusqu à l état le reçu que l établissement a retiré',
    setUp: () {
      when(() => useCase(any())).thenAnswer(
        (_) async =>
            _document(number: 'ETL-RC-2526-000212', status: 'DEFINITIVE'),
      );
      when(
        () => cachedUseCase(
          documentId: any(named: 'documentId'),
          documentNumber: any(named: 'documentNumber'),
        ),
      ).thenAnswer(
        (_) async => EditiqueCacheEntry(
          id: 'c-1',
          documentId: 'doc-1',
          documentNumber: 'ETL-RC-2526-000212',
          docType: 'RC',
          schoolId: 'school-1',
          sizeBytes: 1024,
          contentSha256: 'abc',
          cancelledAt: 1786013000000,
          cancellationReason: 'Erreur de montant',
          createdAt: 1000,
          lastAccessedAt: 1000,
        ),
      );
    },
    build: () => PaymentReceiptCubit(useCase, cachedUseCase),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.cached?.isCancelled, 'cached.isCancelled', isTrue)
          .having(
            (s) => s.cached?.cancellationReason,
            'cached.cancellationReason',
            'Erreur de montant',
          )
          // Les octets restent : la copie annulée se ressort quand même.
          .having((s) => s.cached?.hasBytes, 'cached.hasBytes', isTrue),
    ],
  );
}
