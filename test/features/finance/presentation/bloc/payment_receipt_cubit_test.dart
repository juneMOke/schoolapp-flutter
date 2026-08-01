import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
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

void main() {
  late MockGetPaymentReceiptDocumentUseCase useCase;

  setUp(() => useCase = MockGetPaymentReceiptDocumentUseCase());

  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'expose un numéro définitif tel quel',
    setUp: () => when(() => useCase(any())).thenAnswer(
      (_) async =>
          _document(number: 'ETL-RC-2526-000212', status: 'DEFINITIVE'),
    ),
    build: () => PaymentReceiptCubit(useCase),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.number, 'number', 'ETL-RC-2526-000212')
          .having((s) => s.isProvisional, 'isProvisional', isFalse)
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
    build: () => PaymentReceiptCubit(useCase),
    act: (cubit) => cubit.load('pay-1'),
    expect: () => [
      isA<PaymentReceiptState>()
          .having((s) => s.isProvisional, 'isProvisional', isTrue)
          .having((s) => s.hasDefinitiveNumber, 'hasDefinitiveNumber', isFalse),
    ],
  );

  blocTest<PaymentReceiptCubit, PaymentReceiptState>(
    'reste neutre quand aucun reçu local n existe',
    setUp: () => when(() => useCase(any())).thenAnswer((_) async => null),
    build: () => PaymentReceiptCubit(useCase),
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
}
