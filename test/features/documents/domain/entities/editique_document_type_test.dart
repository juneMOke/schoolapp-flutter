import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

void main() {
  // Cette matrice est une règle métier, pas un détail : un rejeu sur une pièce
  // non archivée consomme un second numéro de séquence côté serveur et crée un
  // doublon invisible du client. Si ce test tombe, c'est la numérotation légale
  // des pièces qui est en jeu.
  group('EditiqueDocumentType — régime d archivage', () {
    const archived = <EditiqueDocumentType>[
      EditiqueDocumentType.enrollmentAttestation,
      EditiqueDocumentType.notePerception,
      EditiqueDocumentType.paymentReceipt,
    ];
    const timestamped = <EditiqueDocumentType>[
      EditiqueDocumentType.accountStatement,
      EditiqueDocumentType.financialClearance,
    ];

    test('AI, NP et RC sont archivées donc rejouables', () {
      for (final type in archived) {
        expect(type.isArchived, isTrue, reason: type.name);
        expect(type.isReplayable, isTrue, reason: type.name);
      }
    });

    test('RL et QT ne sont pas archivées donc jamais rejouables', () {
      for (final type in timestamped) {
        expect(type.isArchived, isFalse, reason: type.name);
        expect(type.isReplayable, isFalse, reason: type.name);
      }
    });

    test('la matrice couvre tous les types déclarés', () {
      expect(<EditiqueDocumentType>{
        ...archived,
        ...timestamped,
      }, EditiqueDocumentType.values.toSet());
    });

    test('chaque type porte le préfixe de numéro du serveur', () {
      expect(EditiqueDocumentType.enrollmentAttestation.code, 'AI');
      expect(EditiqueDocumentType.notePerception.code, 'NP');
      expect(EditiqueDocumentType.paymentReceipt.code, 'RC');
      expect(EditiqueDocumentType.accountStatement.code, 'RL');
      expect(EditiqueDocumentType.financialClearance.code, 'QT');
    });
  });
}
