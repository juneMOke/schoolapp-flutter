import 'package:equatable/equatable.dart';

/// Une ligne de répartition du versement (zone Z5).
class TicketAllocationLine extends Equatable {
  final String label;
  final int amountInCents;

  const TicketAllocationLine({
    required this.label,
    required this.amountInCents,
  });

  @override
  List<Object?> get props => [label, amountInCents];
}

/// Libellés fixes du ticket, injectés depuis `AppLocalizations`.
///
/// Le modèle et son rendu restent **purs** — aucun `BuildContext`, aucune
/// dépendance Flutter — tout en respectant l'interdiction des chaînes en dur :
/// c'est l'appelant qui traduit, le gabarit qui arrange.
class TicketLabels extends Equatable {
  final String provisionalBanner;
  final String referenceLabel;
  final String cashierLabel;
  final String studentLabel;
  final String matriculationLabel;
  final String classroomLabel;
  final String amountReceivedLabel;
  final String allocationsLabel;
  final String balanceLabel;

  /// « sous réserve de synchronisation » — n'accompagne QUE le solde.
  final String balanceReservation;

  /// « Conservez ce ticket jusqu'à la remise de votre reçu définitif. »
  final String keepTicketNotice;

  const TicketLabels({
    required this.provisionalBanner,
    required this.referenceLabel,
    required this.cashierLabel,
    required this.studentLabel,
    required this.matriculationLabel,
    required this.classroomLabel,
    required this.amountReceivedLabel,
    required this.allocationsLabel,
    required this.balanceLabel,
    required this.balanceReservation,
    required this.keepTicketNotice,
  });

  @override
  List<Object?> get props => [
    provisionalBanner,
    referenceLabel,
    cashierLabel,
    studentLabel,
    matriculationLabel,
    classroomLabel,
    amountReceivedLabel,
    allocationsLabel,
    balanceLabel,
    balanceReservation,
    keepTicketNotice,
  ];
}

/// Le reçu provisoire, tel qu'il sera imprimé.
///
/// **Ce n'est pas un fichier** (ADR-012 D-3) : c'est une projection déterministe
/// de lignes SQLite déjà écrites. Tant que la ligne de paiement est en attente
/// de synchro, réimprimer produit exactement le même artefact — c'est ce que
/// garantissent les colonnes stampées à l'encaissement (caissier, appareil,
/// numéro provisoire), et non une quelconque mise en cache.
///
/// Tous les champs d'identité sont **nullables**, et c'est structurel :
/// `students.matriculation_number` est NULL hors ligne par construction (il est
/// attribué à l'ACK), la classe l'est tant que le roster n'a pas été pullé, et
/// le caissier peut ne pas avoir d'identité résoluble. Le gabarit sait taire ce
/// qu'il ne connaît pas — il n'invente jamais.
class TicketReceiptModel extends Equatable {
  // ── Z1 : l'établissement ────────────────────────────────────────────────────
  final String schoolName;
  final String? schoolMunicipality;

  // ── Z2 : l'élève ────────────────────────────────────────────────────────────
  final String studentFullName;
  final String? matriculationNumber;
  final String? classroomName;

  // ── Z3 : la traçabilité ─────────────────────────────────────────────────────
  /// `PROV-<idAppareil>-<uuid>`, en clair. Jamais de QR (Z4) : un code
  /// vérifiable sur une pièce non scellée serait un mensonge.
  final String provisionalReference;
  final DateTime paidAt;
  final String? cashierFullName;

  // ── Z5 : l'argent ───────────────────────────────────────────────────────────
  final int amountReceivedInCents;
  final List<TicketAllocationLine> allocations;

  /// Solde restant **après** ce versement, tel que le local le compose. `null`
  /// quand il n'est pas calculable : mieux vaut omettre la ligne que d'imprimer
  /// un chiffre faux sur un papier remis à un parent.
  final int? remainingBalanceInCents;

  final String currency;
  final TicketLabels labels;

  const TicketReceiptModel({
    required this.schoolName,
    this.schoolMunicipality,
    required this.studentFullName,
    this.matriculationNumber,
    this.classroomName,
    required this.provisionalReference,
    required this.paidAt,
    this.cashierFullName,
    required this.amountReceivedInCents,
    this.allocations = const <TicketAllocationLine>[],
    this.remainingBalanceInCents,
    required this.currency,
    required this.labels,
  });

  @override
  List<Object?> get props => [
    schoolName,
    schoolMunicipality,
    studentFullName,
    matriculationNumber,
    classroomName,
    provisionalReference,
    paidAt,
    cashierFullName,
    amountReceivedInCents,
    allocations,
    remainingBalanceInCents,
    currency,
    labels,
  ];
}
