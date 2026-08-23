import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

void main() {
  group('isUnjustifiedAbsence — le verdict, à sa source', () {
    test(
      'unjustified et unknown sont injustifiés, tout autre motif justifie',
      () {
        expect(isUnjustifiedAbsence(AbsenceReason.unjustified), isTrue);
        expect(isUnjustifiedAbsence(AbsenceReason.unknown), isTrue);

        final justified = AbsenceReason.values.where(
          (r) => r != AbsenceReason.unjustified && r != AbsenceReason.unknown,
        );
        for (final reason in justified) {
          expect(
            isUnjustifiedAbsence(reason),
            isFalse,
            reason: '$reason ne doit pas etre injustifie',
          );
        }
      },
    );

    test('motif absent = injustifiée, et la fonction l\'accepte', () {
      // Le cas que l'ancienne API rendait impossible à poser : la règle vivait
      // sur un getter d'extension, donc chaque appelant tranchait `null` pour
      // son compte. Deux le rangeaient du côté justifié, un du côté injustifié.
      expect(isUnjustifiedAbsence(null), isTrue);
    });
  });

  group('kSelectableAbsenceReasons — la liste de SAISIE', () {
    test('les cinq congés de salarié n\'y sont pas', () {
      for (final salarie in const [
        AbsenceReason.vacation,
        AbsenceReason.underGraduateLeave,
        AbsenceReason.marriageLeave,
        AbsenceReason.parentalLeave,
        AbsenceReason.workLeave,
      ]) {
        expect(
          kSelectableAbsenceReasons,
          isNot(contains(salarie)),
          reason: '$salarie est un congé de salarié, pas un motif d\'élève',
        );
      }
    });

    test('unjustified n\'y est pas : c\'est un verdict, pas un motif', () {
      expect(
        kSelectableAbsenceReasons,
        isNot(contains(AbsenceReason.unjustified)),
      );
      // Mais il RESTE au catalogue : des lignes le portent déjà, et le retirer
      // ferait tomber leur parsing sur le repli défensif.
      expect(AbsenceReason.values, contains(AbsenceReason.unjustified));
    });

    test('unknown Y EST, et il porte le verdict', () {
      // Le point qui tient tout : sans lui, plus aucune valeur du côté
      // injustifié n'est atteignable — l'appel interdisant d'enregistrer sans
      // motif — et le taux d'absences injustifiées tend structurellement vers
      // zéro. Un indicateur qui affiche encore un chiffre sans rien mesurer.
      expect(kSelectableAbsenceReasons, contains(AbsenceReason.unknown));
      expect(isUnjustifiedAbsence(AbsenceReason.unknown), isTrue);
    });

    test('au moins un motif proposé reste du côté justifié', () {
      // Contre-épreuve : une liste dont TOUT serait injustifié rendrait le
      // verdict aussi vide que l'inverse.
      expect(
        kSelectableAbsenceReasons.any((r) => !isUnjustifiedAbsence(r)),
        isTrue,
      );
    });
  });

  group('fromApiValue — parsing défensif (invariant #9)', () {
    test('valeurs cataloguées mappées (dont UNKNOWN, distinct de OTHER)', () {
      expect(AbsenceReasonX.fromApiValue('SICKNESS'), AbsenceReason.sickness);
      expect(AbsenceReasonX.fromApiValue('UNKNOWN'), AbsenceReason.unknown);
      expect(AbsenceReasonX.fromApiValue('OTHER'), AbsenceReason.other);
      expect(AbsenceReasonX.fromApiValue('sickness'), AbsenceReason.sickness);
      expect(AbsenceReasonX.fromApiValue(null), isNull);
    });

    test(
      'motif ENRICHI côté back mais inconnu → unsupported (jamais d\'exception)',
      () {
        // Une valeur ajoutée au catalogue serveur, absente de cette tablette,
        // ne doit pas faire tomber le parsing.
        expect(
          AbsenceReasonX.fromApiValue('DETENTION_SUSPENSION'),
          AbsenceReason.unsupported,
        );
      },
    );

    test(
      'le repli n\'est NI `other` NI `unknown` — les trois sont distincts',
      () {
        // C'est tout l'objet de la sentinelle. `other` est un choix
        // d'enseignant ; les confondre faisait réécrire silencieusement la
        // donnée du serveur, l'écran renvoyant toutes les lignes du brouillon à
        // chaque enregistrement. `unknown`, lui, est CATALOGUÉ et porte le
        // verdict « pas justifiée ».
        final repli = AbsenceReasonX.fromApiValue('DETENTION_SUSPENSION');
        expect(repli, isNot(AbsenceReason.other));
        expect(repli, isNot(AbsenceReason.unknown));
      },
    );
  });

  group('unsupported — la sentinelle front', () {
    test('n\'est pas proposée à la saisie', () {
      expect(
        kSelectableAbsenceReasons,
        isNot(contains(AbsenceReason.unsupported)),
      );
    });

    test('n\'a pas de valeur sur le fil : sérialiser lève', () {
      // Écrire `OTHER` ici rétablirait le défaut en silence. Lever est
      // inatteignable par construction — l'écran bloque avant — mais c'est le
      // filet qui rend l'inatteignabilité vérifiable.
      expect(
        () => AbsenceReason.unsupported.toApiValue(),
        throwsA(isA<StateError>()),
      );
    });

    test('compte comme JUSTIFIÉE, et c\'est ce que le serveur en dit', () {
      // Le verdict serveur est « null, UNKNOWN ou UNJUSTIFIED ⇒ injustifiée ;
      // tout le reste ⇒ justifiée ». Une valeur que le client ne reconnaît pas
      // n'est, par définition, aucune des trois : le serveur la compte donc
      // justifiée, et le calcul local doit dire la même chose — sinon la
      // synthèse élève contredit le tableau de bord sur cette ligne.
      expect(isUnjustifiedAbsence(AbsenceReason.unsupported), isFalse);
    });
  });
}
