import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class CreatePaymentAllocationInput extends Equatable {
  final String studentChargeId;

  /// Ligne de grille visée, quand le frais en désigne une.
  ///
  /// Sur le chemin de synchro, c'est **le** discriminant : un niveau peut porter
  /// plusieurs lignes d'une même nature (un minerval en tranches), et le serveur
  /// refuse alors d'imputer au hasard. `null` = créance *ad hoc*, hors grille.
  ///
  /// Le chemin en ligne du back-office ne le consomme pas : là, l'id de créance
  /// vient d'une liste que le serveur a lui-même servie, et il fait autorité.
  final String? feeTariffId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const CreatePaymentAllocationInput({
    required this.studentChargeId,
    this.feeTariffId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  @override
  List<Object?> get props => [
    studentChargeId,
    feeTariffId,
    feeCode,
    studentChargeLabel,
    amountInCents,
    currency,
  ];
}

abstract class PaymentsRepository {
  Future<Either<Failure, List<Payment>>> getPaymentsByStudentAndAcademicYear({
    required String studentId,
    required String academicYearId,
  });

  Future<Either<Failure, Payment>> createPayment({
    required String studentId,
    required String academicYearId,
    required MoneyBag amounts,
    required String payerFirstName,
    required String payerLastName,
    String? payerMiddleName,
    String? payerPhoneNumber,
    required List<CreatePaymentAllocationInput> allocations,
  });

  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByPaymentId({required String paymentId});
}
