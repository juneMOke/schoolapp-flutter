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
  /// Nature de la pièce, imprimée en tête : « Ticket de perception ».
  ///
  /// ⚠️ **Distinct de la « note de perception »** (`EditiqueDocumentType.NP`),
  /// qui est une pièce **annuelle scellée** au niveau élève. Deux objets
  /// différents : celui-ci atteste **le montant reçu** lors d'un encaissement,
  /// trop-perçu ou non — l'imputation exacte appartient au reçu scellé.
  final String documentTitle;

  final String provisionalBanner;
  final String referenceLabel;
  final String cashierLabel;
  final String studentLabel;
  final String matriculationLabel;
  final String classroomLabel;
  final String amountReceivedLabel;
  final String allocationsLabel;

  /// Part du montant reçu qu'aucune créance n'absorbe — imprimée comme dernière
  /// ligne de la répartition, et seulement quand elle est strictement positive.
  ///
  /// Le ticket **atteste le montant perçu**, il n'arbitre pas son imputation :
  /// c'est le reçu scellé qui fait apparaître le trop-perçu. Ce libellé n'est là
  /// que pour empêcher un écart muet entre le reçu et la ventilation.
  final String advanceLabel;

  final String balanceLabel;

  /// « sous réserve de synchronisation » — n'accompagne QUE le solde.
  final String balanceReservation;

  /// « Conservez ce ticket jusqu'à la remise de votre reçu définitif. »
  final String keepTicketNotice;

  const TicketLabels({
    required this.documentTitle,
    required this.provisionalBanner,
    required this.referenceLabel,
    required this.cashierLabel,
    required this.studentLabel,
    required this.matriculationLabel,
    required this.classroomLabel,
    required this.amountReceivedLabel,
    required this.allocationsLabel,
    required this.advanceLabel,
    required this.balanceLabel,
    required this.balanceReservation,
    required this.keepTicketNotice,
  });

  @override
  List<Object?> get props => [
    documentTitle,
    provisionalBanner,
    referenceLabel,
    cashierLabel,
    studentLabel,
    matriculationLabel,
    classroomLabel,
    amountReceivedLabel,
    allocationsLabel,
    advanceLabel,
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
  ///
  /// ⚠️ **Arbitré le 2026-08-12, ne pas rouvrir sur la seule lecture de
  /// l'ADR-013.** Celui-ci demande un QR portant l'UUID du `Payment`, comme
  /// invariant de construction — « référence, jamais un sceau », donc un
  /// pointeur vers le portail parent, pas une preuve d'authenticité. La
  /// décision retenue est **D-4 (ADR-012)** : le ticket doit rester
  /// délibérément dissemblable du scellé. Un parent qui voit un QR conclut que
  /// le papier est officiel, et la mention « Conservez ce ticket jusqu'à la
  /// remise de votre reçu définitif » perd alors son sens.
  ///
  /// Ajouter un QR ici ne se fait donc qu'après avoir tranché **ce
  /// conflit-là**, pas en appliquant l'ADR-013 à la lettre.
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

  /// Somme des lignes de répartition. Dérivée, jamais stockée.
  ///
  /// ⚠️ **Peut être inférieure à [amountReceivedInCents]**, et ce n'est pas une
  /// anomalie de composition : un versement qui dépasse le dû est accepté
  /// (`PaymentAnomalyKind.overpayment`), le reçu définitif est scellé, et le
  /// ticket remis au parent reste valide. L'écart s'imprime en « avance ».
  int get allocatedInCents =>
      allocations.fold<int>(0, (sum, line) => sum + line.amountInCents);

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
