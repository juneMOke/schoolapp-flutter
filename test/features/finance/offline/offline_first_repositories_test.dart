import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/payments_offline_first_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/student_charges_offline_first_repository.dart';

import '../../offline_full_db.dart';

/// Délégué online factice : n'est appelé que pour les méthodes admin/create.
class _FakeStudentChargesOnline implements StudentChargesRepository {
  bool updateCalled = false;

  @override
  Future<Either<Failure, StudentCharge>> updateStudentChargeExpectedAmount({
    required String studentChargeId,
    required String studentId,
    required double expectedAmountInCents,
  }) async {
    updateCalled = true;
    return Right(
      StudentCharge(
        id: studentChargeId,
        studentId: studentId,
        academicYearId: 'ay-1',
        schoolLevelId: '',
        schoolLevelGroupId: '',
        feeTariffId: '',
        feeCode: 'TUITION',
        label: 'Scolarité',
        expectedAmountInCents: expectedAmountInCents,
        amountPaidInCents: 0,
        currency: 'USD',
        status: StudentChargeStatus.due,
      ),
    );
  }

  @override
  Future<Either<Failure, List<StudentCharge>>> getStudentCharges({
    required String studentId,
    required String levelId,
  }) => throw UnimplementedError('lecture servie en local');

  @override
  Future<Either<Failure, List<StudentCharge>>> getStudentChargesByAcademicYear({
    required String studentId,
    required String academicYearId,
  }) => throw UnimplementedError('lecture servie en local');

  @override
  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByChargeId({required String chargeId}) =>
      throw UnimplementedError('lecture servie en local');
}

class _FakePaymentsOnline implements PaymentsRepository {
  bool createCalled = false;

  @override
  Future<Either<Failure, Payment>> createPayment({
    required String studentId,
    required String academicYearId,
    required int amountInCents,
    required String currency,
    required String payerFirstName,
    required String payerLastName,
    String? payerMiddleName,
    required List<CreatePaymentAllocationInput> allocations,
  }) async {
    createCalled = true;
    return Right(
      Payment(
        id: 'srv',
        studentId: studentId,
        academicYearId: academicYearId,
        amountInCents: amountInCents,
        currency: currency,
        payerFirstName: payerFirstName,
        payerLastName: payerLastName,
        paidAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByStudentAndAcademicYear({
    required String studentId,
    required String academicYearId,
  }) => throw UnimplementedError('lecture servie en local');

  @override
  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByPaymentId({required String paymentId}) =>
      throw UnimplementedError('lecture servie en local');
}

void main() {
  late Database db;
  late FinanceLocalDao dao;
  // Refresh best-effort neutralisé en test (aucun réseau).
  Future<void> noRefresh(String _, String _) async {}

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FinanceLocalDao(db, const IdGenerator(Uuid()));
  });

  tearDown(() async => db.close());

  Future<void> insertCharge(
    String id,
    String studentId,
    String feeCode, {
    int expected = 100000,
    int paid = 0,
    String year = 'ay-1',
  }) => db.insert('student_charges', {
    'id': id,
    'student_id': studentId,
    'academic_year_id': year,
    'fee_code': feeCode,
    'label': feeCode,
    'expected_amount_in_cents': expected,
    'amount_paid_in_cents': paid,
    'optimistic_paid_in_cents': paid,
    'currency': 'USD',
    'status': 'DUE',
    'sync_status': 'SYNCED',
  });

  group('StudentChargesOfflineFirstRepository', () {
    test(
      'getStudentChargesByAcademicYear : reste composé + scope année',
      () async {
        await insertCharge(
          'c1',
          's1',
          'TUITION',
          expected: 100000,
          paid: 40000,
        );
        await insertCharge('c2', 's1', 'CANTEEN', year: 'ay-2'); // autre année
        // Encaissement local non remonté → pending composé sur c1.
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'p1',
            clientUuid: 'p1',
            studentId: 's1',
            academicYearId: 'ay-1',
            amountInCents: 30000,
            currency: 'USD',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'S',
            payerLastName: 'M',
          ),
          allocations: const [
            PaymentAllocationLocalModel(
              id: 'a1',
              clientUuid: 'a1',
              paymentId: 'p1',
              studentChargeId: 'c1',
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
          outboxEntryId: 'ob1',
          nowMs: 1000,
        );

        final repo = StudentChargesOfflineFirstRepository(
          dao: dao,
          refresh: noRefresh,
          online: _FakeStudentChargesOnline(),
        );

        final result = await repo.getStudentChargesByAcademicYear(
          studentId: 's1',
          academicYearId: 'ay-1',
        );
        final charges = result.getOrElse(() => []);
        expect(charges, hasLength(1), reason: 'ay-2 exclu');
        expect(charges.single.amountPaidInCents, 40000.0, reason: 'miroir');
        expect(charges.single.amountPaidPendingInCents, 30000.0);
        expect(
          charges.single.remainingInCents,
          30000.0,
          reason: 'reste composé',
        );
      },
    );

    test('updateStudentChargeExpectedAmount délégué à l\'online', () async {
      final online = _FakeStudentChargesOnline();
      final repo = StudentChargesOfflineFirstRepository(
        dao: dao,
        refresh: noRefresh,
        online: online,
      );
      await repo.updateStudentChargeExpectedAmount(
        studentChargeId: 'c1',
        studentId: 's1',
        expectedAmountInCents: 120000,
      );
      expect(online.updateCalled, isTrue);
    });
  });

  group('PaymentsOfflineFirstRepository', () {
    test(
      'getPaymentsByStudentAndAcademicYear : mappe + isPendingSync',
      () async {
        await dao.recordPayment(
          payment: const PaymentLocalModel(
            id: 'p1',
            clientUuid: 'p1',
            studentId: 's1',
            academicYearId: 'ay-1',
            amountInCents: 30000,
            currency: 'USD',
            paidAt: '2026-07-06T10:00:00Z',
            payerFirstName: 'Sarah',
            payerLastName: 'Moke',
          ),
          allocations: const [],
          outboxEntryId: 'ob1',
          nowMs: 1000,
        );

        final repo = PaymentsOfflineFirstRepository(
          dao: dao,
          refresh: noRefresh,
          online: _FakePaymentsOnline(),
        );
        final result = await repo.getPaymentsByStudentAndAcademicYear(
          studentId: 's1',
          academicYearId: 'ay-1',
        );
        final payments = result.getOrElse(() => []);
        expect(payments, hasLength(1));
        expect(payments.single.isPendingSync, isTrue, reason: 'PENDING_SYNC');
        expect(payments.single.payerFirstName, 'Sarah');
      },
    );

    test(
      'createPayment délégué à l\'online (chemin non emprunté par l\'UI)',
      () async {
        final online = _FakePaymentsOnline();
        final repo = PaymentsOfflineFirstRepository(
          dao: dao,
          refresh: noRefresh,
          online: online,
        );
        await repo.createPayment(
          studentId: 's1',
          academicYearId: 'ay-1',
          amountInCents: 30000,
          currency: 'USD',
          payerFirstName: 'S',
          payerLastName: 'M',
          allocations: const [],
        );
        expect(online.createCalled, isTrue);
      },
    );
  });
}
