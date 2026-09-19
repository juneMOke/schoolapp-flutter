import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipt.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_receipt_record_intent.dart';

/// La règle de l'œil de la caisse : **cette ligne ouvre-t-elle une fiche, et sur
/// quoi ?**
///
/// Elle est éprouvée ici parce qu'elle est pure : ni widget, ni routeur, ni
/// BLoC. Ce que ces cas défendent tient en une phrase — l'œil ne doit jamais
/// promettre une ouverture que l'écran suivant refuserait, en rendant sa carte
/// « contexte indisponible » à la place du grand-livre.
TillReceipt _receipt({
  String? studentId = 'stu-1',
  String? firstName = 'Kevin',
  String? lastName = 'MAKELA',
  String? surname = 'Mbuyi',
  String? studentName = 'MAKELA Kevin Mbuyi',
}) => TillReceipt(
  paymentId: 'pay-1',
  paidAt: DateTime.utc(2026, 9, 18, 7, 41),
  source: 'FACTURATION',
  amount: 115000,
  currency: 'CDF',
  studentName: studentName,
  classroom: '5e A',
  studentId: studentId,
  firstName: firstName,
  lastName: lastName,
  surname: surname,
);

void main() {
  group('la ligne porte de quoi ouvrir', () {
    test(
      'l intent reprend l identite de la ligne et l annee de l enveloppe',
      () {
        final intent = tillReceiptRecordIntent(
          _receipt(),
          academicYearId: 'ay-2526',
        );

        expect(intent, isNotNull);
        expect(intent!.studentId, 'stu-1');
        // L'année ne vient PAS de la ligne : c'est le paramètre sur lequel la
        // requête a filtré, porté une fois par l'enveloppe de la page.
        expect(intent.academicYearId, 'ay-2526');
        expect(intent.firstName, 'Kevin');
        expect(intent.lastName, 'MAKELA');
        expect(intent.surname, 'Mbuyi');
      },
    );

    test('le post-nom absent n empeche rien', () {
      // Beaucoup d'élèves n'en ont pas, et la fiche filtre les composants vides
      // avant de composer le nom qu'elle affiche.
      final intent = tillReceiptRecordIntent(
        _receipt(surname: null),
        academicYearId: 'ay-2526',
      );

      expect(intent, isNotNull);
      expect(intent!.surname, isEmpty);
    });

    test('les espaces autour des valeurs sont retires', () {
      final intent = tillReceiptRecordIntent(
        _receipt(
          studentId: '  stu-1 ',
          firstName: ' Kevin',
          lastName: 'MAKELA ',
        ),
        academicYearId: '  ay-2526  ',
      );

      expect(intent!.studentId, 'stu-1');
      expect(intent.academicYearId, 'ay-2526');
      expect(intent.firstName, 'Kevin');
      expect(intent.lastName, 'MAKELA');
    });

    /// La caisse ne porte ni niveau ni cycle — seulement une classe en texte
    /// libre, qui n'est ni l'un ni l'autre. La fiche s'ouvre sans eux et affiche
    /// « Facturation · - » : les exiger avait déjà coûté une carte d'erreur pour
    /// un élève parfaitement identifié.
    test('niveau et cycle restent vides, et c est assume', () {
      final intent = tillReceiptRecordIntent(
        _receipt(),
        academicYearId: 'ay-2526',
      );

      expect(intent!.levelName, isEmpty);
      expect(intent.levelGroupName, isEmpty);
      // Ce que la fiche exige réellement pour charger le grand-livre.
      expect(intent.hasStudentIdentity, isTrue);
    });
  });

  group('rien a ouvrir — l oeil doit rester eteint', () {
    test('sans identifiant : le serveur ne sert pas encore le champ', () {
      expect(
        tillReceiptRecordIntent(
          _receipt(studentId: null),
          academicYearId: 'ay-2526',
        ),
        isNull,
      );
    });

    test('sans nom ni prenom : l annuaire ne resout plus l eleve', () {
      // ⚠️ Le cas que le back a nommé : `studentId` reste bon, mais le nom est
      // absent. La ligne affiche un tiret ; la fiche, elle, ne chargerait rien.
      expect(
        tillReceiptRecordIntent(
          _receipt(firstName: null, lastName: null, studentName: null),
          academicYearId: 'ay-2526',
        ),
        isNull,
      );
    });

    test('sans prenom seul', () {
      expect(
        tillReceiptRecordIntent(
          _receipt(firstName: null),
          academicYearId: 'ay-2526',
        ),
        isNull,
      );
    });

    test('sans nom seul', () {
      expect(
        tillReceiptRecordIntent(
          _receipt(lastName: null),
          academicYearId: 'ay-2526',
        ),
        isNull,
      );
    });

    test('une valeur reduite a des espaces vaut absente', () {
      expect(
        tillReceiptRecordIntent(
          _receipt(studentId: '   '),
          academicYearId: 'ay-2526',
        ),
        isNull,
      );
    });

    test('sans annee : la route manquerait son second parametre', () {
      // Le redirect de garde de la route renverrait sur /facturations — autant
      // ne rien promettre.
      expect(tillReceiptRecordIntent(_receipt(), academicYearId: null), isNull);
      expect(tillReceiptRecordIntent(_receipt(), academicYearId: '  '), isNull);
    });
  });

  /// ⚠️ **Deux gardes, une seule règle.** La table éteint son œil sur
  /// `canOpenFinancialRecord` ; l'onglet refuse de pousser quand l'intent est
  /// `null`. Si les deux divergeaient, l'œil promettrait ce que la navigation
  /// refuse — ou l'inverse, ce qui rendrait un geste impossible à déclencher.
  group('les deux gardes s accordent', () {
    final cas = <String, TillReceipt>{
      'complet': _receipt(),
      'sans post-nom': _receipt(surname: null),
      'sans identifiant': _receipt(studentId: null),
      'sans prenom': _receipt(firstName: null),
      'sans nom': _receipt(lastName: null),
      'identifiant en espaces': _receipt(studentId: ' '),
    };

    for (final entry in cas.entries) {
      test('${entry.key} : le grisage et l intent disent la meme chose', () {
        final receipt = entry.value;
        final intent = tillReceiptRecordIntent(
          receipt,
          academicYearId: 'ay-2526',
        );

        expect(
          intent != null,
          receipt.canOpenFinancialRecord,
          reason:
              'l œil serait ${receipt.canOpenFinancialRecord ? "actif" : "éteint"} '
              'alors que la navigation ${intent != null ? "accepte" : "refuse"}',
        );
      });
    }

    test(
      'l annee manquante eteint l oeil SANS toucher a la regle de ligne',
      () {
        // La ligne reste ouvrable en soi ; c'est l'enveloppe qui manque. La
        // distinction compte : le jour où l'année est servie, rien d'autre ne
        // change.
        final receipt = _receipt();

        expect(receipt.canOpenFinancialRecord, isTrue);
        expect(tillReceiptRecordIntent(receipt, academicYearId: null), isNull);
      },
    );
  });
}
