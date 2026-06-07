import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/create_payment_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payment_allocations_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payments_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetPayments extends Mock implements GetPaymentsUseCase {}

class _MockGetAllocations extends Mock
    implements GetPaymentAllocationsUseCase {}

class _MockCreatePayment extends Mock implements CreatePaymentUseCase {}

const _request = PaymentsCreateRequested(
  studentId: 's1',
  academicYearId: 'y1',
  amountInCents: 700000,
  currency: 'CDF',
  payerFirstName: 'Paul',
  payerLastName: 'Mukendi',
  payerMiddleName: null,
  allocations: [
    CreatePaymentAllocationInput(
      studentChargeId: 'c1',
      feeCode: 'TUITION',
      studentChargeLabel: 'Frais',
      amountInCents: 700000,
      currency: 'CDF',
    ),
  ],
);

final _payment = Payment(
  id: 'pay-42',
  studentId: 's1',
  academicYearId: 'y1',
  amountInCents: 700000,
  currency: 'CDF',
  payerFirstName: 'Paul',
  payerLastName: 'Mukendi',
  paidAt: DateTime(2026, 6, 7),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(const <CreatePaymentAllocationInput>[]));

  late _MockCreatePayment createUseCase;
  late PaymentsBloc bloc;

  setUp(() {
    createUseCase = _MockCreatePayment();
    bloc = PaymentsBloc(
      getPaymentsUseCase: _MockGetPayments(),
      createPaymentUseCase: createUseCase,
      getPaymentAllocationsUseCase: _MockGetAllocations(),
    );
  });

  tearDown(() => bloc.close());

  Future<FacturationCollectOutcome?> open(WidgetTester tester) async {
    FacturationCollectOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                outcome = await showFacturationCreatePaymentConfirmDialog(
                  context,
                  paymentsBloc: bloc,
                  totalLabel: '7 000 CDF',
                  studentName: 'Kabeya Junior',
                  payerName: 'Mukendi Paul',
                  request: _request,
                  allocations: const [
                    FacturationConfirmAllocationItem(
                      label: 'Frais de scolarité',
                      amount: '7 000 CDF',
                    ),
                  ],
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return outcome;
  }

  testWidgets('étape 1 : indicateur, titre, phrase, répartition, actions', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Confirmation'), findsWidgets); // indicateur + eyebrow
    expect(find.text('Résultat'), findsOneWidget); // pastille étape 2
    expect(find.text('Encaisser 7 000 CDF ?'), findsOneWidget);
    expect(find.textContaining('Kabeya Junior'), findsOneWidget);
    expect(find.text('Frais de scolarité'), findsOneWidget);
    // Le simulateur d'échec a été retiré.
    expect(find.text('Simuler un échec'), findsNothing);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Confirmer'), findsOneWidget);
  });

  testWidgets('« Modifier » retourne edited', (tester) async {
    await open(tester);
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    // Le dialog se referme ; pas d'assertion d'outcome ici (capturé async).
    expect(find.text('Encaisser 7 000 CDF ?'), findsNothing);
  });

  testWidgets('échec bloc → écran erreur (aucun montant débité)', (
    tester,
  ) async {
    when(
      () => createUseCase.call(
        studentId: any(named: 'studentId'),
        academicYearId: any(named: 'academicYearId'),
        amountInCents: any(named: 'amountInCents'),
        currency: any(named: 'currency'),
        payerFirstName: any(named: 'payerFirstName'),
        payerLastName: any(named: 'payerLastName'),
        payerMiddleName: any(named: 'payerMiddleName'),
        allocations: any(named: 'allocations'),
      ),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    await open(tester);

    await tester.tap(find.text('Confirmer'));
    await tester.pump(); // processing
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(); // applique l'échec

    expect(find.text('Échec de l\'encaissement'), findsOneWidget);
    expect(find.text('Aucun montant n\'a été débité.'), findsOneWidget);
    expect(find.textContaining('Code incident'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('« Confirmer » → succès : paiement créé + reçu + callback', (
    tester,
  ) async {
    when(
      () => createUseCase.call(
        studentId: any(named: 'studentId'),
        academicYearId: any(named: 'academicYearId'),
        amountInCents: any(named: 'amountInCents'),
        currency: any(named: 'currency'),
        payerFirstName: any(named: 'payerFirstName'),
        payerLastName: any(named: 'payerLastName'),
        payerMiddleName: any(named: 'payerMiddleName'),
        allocations: any(named: 'allocations'),
      ),
    ).thenAnswer((_) async => Right(_payment));

    await open(tester);

    await tester.tap(find.text('Confirmer'));
    await tester.pump(); // processing
    // Laisse le bloc + usecase (async) se résoudre réellement.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(); // applique le succès
    await tester.pump(const Duration(milliseconds: 600)); // pop/halo

    verify(
      () => createUseCase.call(
        studentId: any(named: 'studentId'),
        academicYearId: any(named: 'academicYearId'),
        amountInCents: any(named: 'amountInCents'),
        currency: any(named: 'currency'),
        payerFirstName: any(named: 'payerFirstName'),
        payerLastName: any(named: 'payerLastName'),
        payerMiddleName: any(named: 'payerMiddleName'),
        allocations: any(named: 'allocations'),
      ),
    ).called(1);

    expect(find.text('Paiement enregistré'), findsOneWidget);
    expect(find.textContaining('Reçu n°'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
  });
}
