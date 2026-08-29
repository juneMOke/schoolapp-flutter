import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_catalog_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

void main() {
  group('barème du catalogue', () {
    test('couvre les cinq pièces scopées ÉLÈVE, sans doublon', () {
      final types = EditiqueCatalogEntry.all
          .map((entry) => entry.type)
          .toList(growable: false);

      expect(types.toSet(), {
        EditiqueDocumentType.enrollmentAttestation,
        EditiqueDocumentType.notePerception,
        EditiqueDocumentType.paymentReceipt,
        EditiqueDocumentType.accountStatement,
        EditiqueDocumentType.financialClearance,
      });
      expect(types.length, types.toSet().length, reason: 'aucun doublon');
    });

    test('le reçu de VENTE en est délibérément absent', () {
      // Le catalogue est celui d'un dossier ÉLÈVE. Le RV ne désigne aucun
      // élève — son sujet est le payeur — et rien de ce dossier ne pourrait
      // l'émettre. L'y ajouter offrirait une ligne que le serveur refuserait,
      // et laisserait croire qu'une vente boutique appartient à la scolarité
      // (invariant I-4).
      expect(
        EditiqueCatalogEntry.all.map((entry) => entry.type),
        isNot(contains(EditiqueDocumentType.saleReceipt)),
      );
    });

    // Invariant de contrat : « figé » n'est pas un choix d'affichage, c'est
    // l'archivage serveur. Si les deux divergeaient, l'UI proposerait un rejeu
    // sûr sur une pièce qui brûle un numéro de séquence à chaque appel.
    test('la nature affichée est exactement l archivage serveur', () {
      for (final entry in EditiqueCatalogEntry.all) {
        expect(
          entry.isArchived,
          entry.type.isArchived,
          reason: 'nature divergente pour ${entry.code}',
        );
      }
    });

    test(
      'range l attestation en Scolarité et les quatre autres en Finances',
      () {
        expect(
          EditiqueCatalogEntry.ofGroup(
            EditiqueCatalogGroup.scolarite,
          ).map((e) => e.type),
          [EditiqueDocumentType.enrollmentAttestation],
        );

        expect(
          EditiqueCatalogEntry.ofGroup(EditiqueCatalogGroup.finances).length,
          4,
        );
      },
    );

    test('n expose aucun groupe vide', () {
      for (final group in EditiqueCatalogGroup.values) {
        expect(
          EditiqueCatalogEntry.ofGroup(group),
          isNotEmpty,
          reason: 'groupe sans pièce : $group',
        );
      }
    });

    test('le code de la pastille est celui du type', () {
      for (final entry in EditiqueCatalogEntry.all) {
        expect(entry.code, entry.type.code);
      }
    });
  });
}
