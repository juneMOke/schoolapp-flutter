import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28). Nul est un état NORMAL : la saisie l'exige
  /// depuis le palier, mais tout versement plus ancien — et tout versement
  /// scellé avant que le contrat ne le porte — n'en a pas.
  final String? payerPhoneNumber;
  final DateTime paidAt;

  /// Paiement de CE poste pas encore remonté au serveur (FRONT §3). Faux pour
  /// les paiements synchronisés (ce poste ou l'autre poste, arrivés par pull).
  final bool isPendingSync;

  /// Qui a encaissé, tel que le poste l'a stampé à l'encaissement (v19).
  ///
  /// ⚠️ **Nul est un état NORMAL et durable, pas un chargement.** Le nom n'est
  /// écrit que par la tablette qui encaisse : aucun contrat de synchronisation
  /// ne le transporte aujourd'hui, et le pull exclut délibérément ces colonnes
  /// de son patch pour ne pas les écraser. Il est donc vide pour tout paiement
  /// venu d'un autre guichet, pour tout encaissement antérieur à la v19, et
  /// quand l'annuaire local était muet au moment du geste.
  ///
  /// Le combler demande que `PaymentDelta`/`PaymentDto` le portent — une
  /// évolution de contrat côté serveur, pas un correctif front.
  final String? cashierFirstName;
  final String? cashierLastName;

  const Payment({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    required this.paidAt,
    this.isPendingSync = false,
    this.cashierFirstName,
    this.cashierLastName,
  });

  /// Nom affichable de l'encaisseur, `null` si rien n'a été stampé.
  ///
  /// Même règle de composition que le ticket
  /// (`TicketPaymentRow.cashierFullName`) : les deux surfaces montrent le même
  /// nom pour le même versement, ou ne montrent rien.
  String? get cashierFullName {
    final parts = [
      cashierFirstName?.trim(),
      cashierLastName?.trim(),
    ].where((part) => part != null && part.isNotEmpty).cast<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    amountInCents,
    currency,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    paidAt,
    isPendingSync,
    cashierFirstName,
    cashierLastName,
  ];
}
