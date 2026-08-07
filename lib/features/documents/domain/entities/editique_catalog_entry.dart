import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

/// Groupe de rangement du catalogue (§06 de la spec).
///
/// Le groupe **Académique** n'existe pas en V1 : sa seule pièce est le bulletin,
/// hors périmètre tant que le serveur n'expose pas son identifiant et ne rend
/// pas son émission idempotente. Afficher un groupe vide laisserait croire à un
/// dossier incomplet plutôt qu'à une fonctionnalité absente.
enum EditiqueCatalogGroup { scolarite, finances }

/// Nature d'une pièce (§08) — la distinction structurante du module.
///
/// Un document **figé** est archivé par le serveur : le re-demander re-sert les
/// mêmes octets sous le même numéro. Un document **horodaté** reflète l'état du
/// compte à l'instant de sa production, n'est jamais archivé, et consomme un
/// numéro de séquence à chaque appel.
enum EditiqueCatalogNature { fige, horodate }

/// Une entrée du barème des pièces (§09) : le contrat d'API rendu visible.
///
/// Toute évolution du serveur se traduit par une entrée de cette table, jamais
/// par du code d'écran.
class EditiqueCatalogEntry {
  final EditiqueDocumentType type;
  final EditiqueCatalogGroup group;
  final EditiqueCatalogNature nature;

  const EditiqueCatalogEntry({
    required this.type,
    required this.group,
    required this.nature,
  });

  String get code => type.code;

  /// Cohérence de contrat : la nature figée est exactement l'archivage serveur.
  /// Les deux notions ne peuvent pas diverger — c'est ce qui rend un rejeu sûr.
  bool get isArchived => nature == EditiqueCatalogNature.fige;

  /// Le barème des cinq pièces que le front sait émettre, dans l'ordre
  /// d'affichage du catalogue.
  static const List<EditiqueCatalogEntry> all = [
    EditiqueCatalogEntry(
      type: EditiqueDocumentType.enrollmentAttestation,
      group: EditiqueCatalogGroup.scolarite,
      nature: EditiqueCatalogNature.fige,
    ),
    EditiqueCatalogEntry(
      type: EditiqueDocumentType.notePerception,
      group: EditiqueCatalogGroup.finances,
      nature: EditiqueCatalogNature.fige,
    ),
    EditiqueCatalogEntry(
      type: EditiqueDocumentType.paymentReceipt,
      group: EditiqueCatalogGroup.finances,
      nature: EditiqueCatalogNature.fige,
    ),
    EditiqueCatalogEntry(
      type: EditiqueDocumentType.accountStatement,
      group: EditiqueCatalogGroup.finances,
      nature: EditiqueCatalogNature.horodate,
    ),
    EditiqueCatalogEntry(
      type: EditiqueDocumentType.financialClearance,
      group: EditiqueCatalogGroup.finances,
      nature: EditiqueCatalogNature.horodate,
    ),
  ];

  static List<EditiqueCatalogEntry> ofGroup(EditiqueCatalogGroup group) =>
      all.where((entry) => entry.group == group).toList(growable: false);
}
