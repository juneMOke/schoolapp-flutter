part of 'payments_bloc.dart';

sealed class PaymentsEvent extends Equatable {
  const PaymentsEvent();
}

class PaymentsRequested extends PaymentsEvent {
  final String studentId;
  final String academicYearId;

  /// Relecture **silencieuse** déclenchée par un cycle de synchro abouti : pas
  /// de passage en `loading` (l'écran garde ses lignes, aucun skeleton ne
  /// revient) et un échec ne détruit pas l'affichage déjà servi. Les états
  /// étant `Equatable`, une relecture qui ne change rien n'émet même pas.
  final bool silent;

  const PaymentsRequested({
    required this.studentId,
    required this.academicYearId,
    this.silent = false,
  });

  @override
  List<Object?> get props => [studentId, academicYearId, silent];
}

class PaymentsAllocationsRequested extends PaymentsEvent {
  final String paymentId;

  const PaymentsAllocationsRequested({required this.paymentId});

  @override
  List<Object?> get props => [paymentId];
}

class PaymentsCreateRequested extends PaymentsEvent {
  final String studentId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28) — obligatoire à la saisie, porté nullable
  /// pour que le contrat reste lisible par un rejeu antérieur au palier.
  final String? payerPhoneNumber;
  final List<CreatePaymentAllocationInput> allocations;

  const PaymentsCreateRequested({
    required this.studentId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.allocations,
  });

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    amountInCents,
    currency,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    allocations,
  ];
}
