import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';

/// Modèles de ticket figés pour le banc d'impression thermique.
///
/// **Pourquoi des modèles figés plutôt que la vraie base.** Caler une page de
/// code, une largeur et une avance papier demande vingt à trente impressions
/// d'affilée. Le seul chemin de production vers un ticket passe par un
/// encaissement réel dans la popin de Facturation : trente versements fictifs
/// écrits dans la base locale pour régler une imprimante serait un remède pire
/// que le mal.
///
/// Ces modèles ne sont donc pas des « exemples » : ce sont les cas qui ont
/// cassé le rendu par le passé, ou qui peuvent le casser.
///
/// Fichier de développement (`kDebugMode` seul) : les chaînes y sont en dur, à
/// l'image de la galerie de composants — un ticket de calage n'est pas de l'UI
/// et ne se traduit pas.
abstract final class TicketBenchFixtures {
  static const TicketLabels labels = TicketLabels(
    provisionalBanner: 'Provisoire',
    referenceLabel: 'Réf.',
    cashierLabel: 'Caissier :',
    studentLabel: 'Élève :',
    matriculationLabel: 'Matricule :',
    classroomLabel: 'Classe :',
    amountReceivedLabel: 'Montant reçu',
    allocationsLabel: 'Répartition',
    advanceLabel: 'Avance',
    balanceLabel: 'Solde',
    balanceReservation: 'sous réserve de synchronisation',
    keepTicketNotice:
        'Conservez ce ticket jusqu\'à la remise de votre reçu définitif.',
  );

  /// Le cas de torture : tout ce qui peut décaler une colonne.
  ///
  /// * `Cœur` et `’` — deux translittérations qui **changent la longueur** de la
  ///   chaîne, donc l'alignement, si elles arrivaient après la mise en colonnes.
  /// * `Ɛ` (latin étendu B, orthographes d'Afrique centrale) — présent dans des
  ///   noms propres réels et absent du Latin-1.
  /// * un nom d'élève assez long pour se replier sur deux lignes ;
  /// * cinq lignes de répartition dont deux libellés trop longs pour tenir en
  ///   face de leur montant — c'est le chemin `_addPair` qui reporte la valeur ;
  /// * un montant à six chiffres, pour voir le groupement des milliers ;
  /// * un solde présent, seul porteur de la mention de réserve.
  static final TicketReceiptModel torture = TicketReceiptModel(
    schoolName: 'Complexe scolaire Sacré-Cœur de l’Étoile',
    schoolMunicipality: 'Kinshasa · Ngaliema',
    studentFullName: 'Mbala-Kasa Ndombasi Amina Ɛlodie',
    matriculationNumber: 'MAT-2026-000481',
    classroomName: '5e primaire A',
    provisionalReference: 'PROV-A1B2C3D4-9F8E7D6C5B4A3928',
    paidAt: DateTime(2026, 8, 11, 14, 7),
    cashierFullName: 'Jean-Baptiste Kabeya wa Mukendi',
    amountReceivedInCents: 12345678,
    allocations: const [
      TicketAllocationLine(label: 'Frais scolaires', amountInCents: 8000000),
      TicketAllocationLine(
        label: 'Frais de fonctionnement et d’entretien annuel',
        amountInCents: 2500000,
      ),
      TicketAllocationLine(label: 'Fournitures', amountInCents: 1000000),
      TicketAllocationLine(label: 'Assurance scolaire', amountInCents: 745678),
      TicketAllocationLine(
        label: 'Participation aux activités parascolaires',
        amountInCents: 100000,
      ),
    ],
    remainingBalanceInCents: 25000000,
    currency: 'CDF',
    labels: labels,
  );

  /// Le ticket du premier jour hors ligne : presque tout est absent.
  ///
  /// `matriculation_number` est **NULL hors ligne par construction** (attribué à
  /// l'ACK), la classe l'est tant que le roster n'a pas été pullé, et le
  /// caissier peut ne pas avoir d'identité résoluble. Le gabarit doit taire ce
  /// qu'il ne connaît pas — c'est ce que ce modèle vérifie sur le papier.
  static final TicketReceiptModel minimal = TicketReceiptModel(
    schoolName: 'EP Kimbanguiste',
    studentFullName: 'Amina Mbala',
    provisionalReference: 'PROV-A1B2C3D4-0001',
    paidAt: DateTime(2026, 8, 11, 8, 3),
    amountReceivedInCents: 500000,
    currency: 'CDF',
    labels: labels,
  );

  /// Ligne d'épreuve de la page de code : les accents du français, plus les
  /// signes qui doivent avoir été translittérés AVANT d'arriver sur le fil.
  ///
  /// C'est elle qu'on imprime sous chaque sélecteur `ESC t n` candidat. La
  /// lecture est binaire : ou bien les accents sortent justes, ou bien la page
  /// n'est pas la bonne.
  static const String codePageProbeLine = 'éèêë àâä ùûü ôö ç ÉÀÇ n°1 « ok »';
}
