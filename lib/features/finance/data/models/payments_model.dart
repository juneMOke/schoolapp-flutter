import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/data/models/money_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';

part 'payments_model.g.dart';

@JsonSerializable()
class PaymentModel extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;

  /// Ce qui a été encaissé, une entrée par devise — dérivé des imputations
  /// côté serveur. Jamais additionné entre entrées.
  final List<MoneyModel> amounts;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final String? payerPhoneNumber;
  final DateTime paidAt;

  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    this.amounts = const [],
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);

  Payment toEntity() => Payment(
    id: id,
    studentId: studentId,
    academicYearId: academicYearId,
    amounts: MoneyBag.of([for (final a in amounts) a.toEntity()]),
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    payerPhoneNumber: payerPhoneNumber,
    paidAt: paidAt,
  );

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    amounts,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    paidAt,
  ];
}
