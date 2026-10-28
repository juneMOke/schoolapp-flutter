import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Quel papier un travail d'impression doit produire.
enum TicketPrintJobKind {
  /// Le ticket de caisse d'un versement.
  receipt,

  /// Le ticket d'annulation d'un versement (continuité RC, lot B).
  cancellation,
}

/// Où en est un ticket de la file.
enum TicketPrintJobState {
  /// Son reçu a un numéro définitif : il peut sortir.
  ready,

  /// Le numéro n'est pas encore attribué — versement ou annulation pas encore
  /// acquittés par le serveur. Il sortira après la synchronisation.
  awaitingNumber,

  /// Numéroté, mais l'élève n'est pas encore descendu sur ce poste : un ticket
  /// qui ne nomme personne n'atteste rien (ADR-015 F1).
  awaitingStudent,
}

/// Un ticket que ce poste doit encore imprimer (continuité RC, lot D).
class TicketPrintJob extends Equatable {
  final String id;
  final String paymentId;
  final TicketPrintJobKind kind;
  final TicketPrintJobState state;

  /// Le numéro définitif du reçu, `null` tant qu'il n'est pas attribué.
  final String? receiptNumber;

  /// Vide quand l'élève n'est pas encore descendu sur ce poste : le ticket ne
  /// sortira pas tant qu'il ne nomme personne (ADR-015 F1).
  final String studentFullName;

  /// Ce que le tiroir a reçu, par devise.
  final MoneyBag amount;

  /// Quand le versement a été saisi.
  final DateTime enteredAt;

  /// La cause du dernier échec d'impression (`ThermalPrinterProblem.name`),
  /// `null` si aucun envoi n'a échoué.
  final String? lastProblem;

  const TicketPrintJob({
    required this.id,
    required this.paymentId,
    required this.kind,
    required this.state,
    required this.receiptNumber,
    required this.studentFullName,
    required this.amount,
    required this.enteredAt,
    this.lastProblem,
  });

  bool get isReady => state == TicketPrintJobState.ready;

  @override
  List<Object?> get props => [
    id,
    paymentId,
    kind,
    state,
    receiptNumber,
    studentFullName,
    amount,
    enteredAt,
    lastProblem,
  ];
}
