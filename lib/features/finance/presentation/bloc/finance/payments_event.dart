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

  /// Ce qui est encaissé, **par devise** : un passage au guichet peut solder
  /// une créance en dollars et une en francs.
  final MoneyBag amounts;

  /// Les trois noms et le numéro sont FACULTATIFS (V114 serveur) : `null` quand
  /// l'argent a été pris sans nommer qui le donnait. Jamais `''` — « pas de
  /// payeur » est un fait, pas un nom de longueur zéro.
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28) — obligatoire à la saisie, porté nullable
  /// pour que le contrat reste lisible par un rejeu antérieur au palier.
  final String? payerPhoneNumber;
  final List<CreatePaymentAllocationInput> allocations;

  /// Ce qui est **entré dans le tiroir**, une entrée par couple (devise reçue,
  /// devise de créance). Vide = identité : le parent règle dans la devise de
  /// chaque créance, ce qui est le cas courant.
  ///
  /// À ne pas confondre avec [amounts], qui reste l'IMPUTÉ. Rien ne relie les
  /// deux sans le taux, et c'est tout l'objet de ces lignes.
  final List<TenderDraft> tenders;

  const PaymentsCreateRequested({
    required this.studentId,
    required this.academicYearId,
    required this.amounts,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.allocations,
    this.tenders = const [],
  });

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    tenders,
    amounts,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    allocations,
  ];
}
