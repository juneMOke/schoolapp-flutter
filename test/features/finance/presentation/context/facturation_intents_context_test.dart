import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';

/// La règle, une fois pour les quatre intents de Facturation : **la classe est
/// du contexte d'affichage, jamais une condition d'ouverture.**
///
/// Une recherche par identité (les trois noms, aucun niveau) ne transmet aucune
/// classe — le résumé d'élève n'en porte pas, et les derniers critères de
/// recherche, seule autre source, sont vides dans ce mode. L'exiger fermait la
/// fiche d'un élève parfaitement identifié.
void main() {
  group('fiche Facturation', () {
    test('une identité sans classe ouvre la fiche', () {
      const intent = FacturationDetailIntent(
        studentId: 's-1',
        academicYearId: 'y-1',
        firstName: 'Daniel',
        lastName: 'Kabongo',
        surname: 'Mwamba',
        levelName: '',
        levelGroupName: '',
      );

      expect(intent.hasStudentIdentity, isTrue);
    });

    test(
      'CONTRE-ÉPREUVE : sans identité, non — on n\'affiche pas un solde sous '
      'un inconnu',
      () {
        const intent = FacturationDetailIntent.invalid(
          studentId: 's-1',
          academicYearId: 'y-1',
        );

        expect(intent.hasStudentIdentity, isFalse);
      },
    );
  });

  group('modales de la fiche', () {
    test('le détail d\'un frais ne réclame pas la classe', () {
      const intent = FacturationChargeDetailIntent(
        chargeId: 'c-1',
        studentId: 's-1',
        academicYearId: 'y-1',
        firstName: 'Daniel',
        lastName: 'Kabongo',
        surname: '',
        levelName: '',
        levelGroupName: '',
        feeCode: 'TUITION',
        expectedAmountInCents: 1000,
        amountPaidInCents: 0,
        currency: 'CDF',
        chargeStatus: StudentChargeStatus.due,
      );

      expect(intent.hasDisplayContext, isTrue);
      // L'identifiant de la ligne, lui, reste exigé : sans lui il n'y a rien à
      // afficher.
      expect(
        const FacturationChargeDetailIntent.invalid(
          chargeId: '',
          studentId: 's-1',
          academicYearId: 'y-1',
        ).hasDisplayContext,
        isFalse,
      );
    });

    test('le détail d\'un versement non plus', () {
      final intent = FacturationPaymentDetailIntent(
        paymentId: 'p-1',
        studentId: 's-1',
        academicYearId: 'y-1',
        firstName: 'Daniel',
        lastName: 'Kabongo',
        surname: '',
        levelName: '',
        levelGroupName: '',
        payerFirstName: 'Jean',
        payerLastName: 'Kabongo',
        payerMiddleName: '',
        amountInCents: 1000,
        currency: 'CDF',
        paidAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(intent.hasDisplayContext, isTrue);
    });

    test('l\'encaissement non plus — la classe ne figure sur aucune pièce', () {
      const intent = FacturationCreatePaymentIntent(
        studentId: 's-1',
        academicYearId: 'y-1',
        firstName: 'Daniel',
        lastName: 'Kabongo',
        surname: '',
        levelName: '',
        levelGroupName: '',
        studentCharges: [],
      );

      expect(intent.hasDisplayContext, isTrue);
    });
  });
}
