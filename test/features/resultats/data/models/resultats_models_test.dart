import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/data/models/domaine_resultat_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultat_focus_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultats_classe_model.dart';

void main() {
  group('DomaineResultatModel (nœud récursif)', () {
    // Domaine racine -> sous-domaine (sousRubriques) -> feuille (branches).
    final json = <String, dynamic>{
      'rubriqueId': 'dom-1',
      'label': 'Sciences',
      'produitSousTotal': true,
      'obtenu': 30.0,
      'max': 40.0,
      'pourcentage': 75.0,
      'sousRubriques': [
        {
          'rubriqueId': 'sd-1',
          'label': 'Maths',
          'produitSousTotal': false,
          'obtenu': 15.0,
          'max': 20.0,
          'pourcentage': null,
          'branches': [
            {
              'ligneBaremeId': 'lb-1',
              'brancheId': 'br-1',
              'brancheNom': 'Algèbre',
              'obtenu': 15.0,
              'max': 20.0,
              'pourcentage': 75.0,
            },
          ],
        },
      ],
    };

    test('fromJson + toEntity mappent l\'arbre récursivement', () {
      final entity = DomaineResultatModel.fromJson(json).toEntity();

      expect(entity.rubriqueId, 'dom-1');
      expect(entity.produitSousTotal, isTrue);
      // Nœud « domaine » : sousRubriques non vide, branches vide.
      expect(entity.sousRubriques, hasLength(1));
      expect(entity.branches, isEmpty);

      final sousDomaine = entity.sousRubriques.single;
      expect(sousDomaine.rubriqueId, 'sd-1');
      // pourcentage null conservé (≠ 0).
      expect(sousDomaine.pourcentage, isNull);
      // Nœud « feuille » : branches non vide, sousRubriques vide.
      expect(sousDomaine.branches, hasLength(1));
      expect(sousDomaine.sousRubriques, isEmpty);
      expect(sousDomaine.branches.single.brancheNom, 'Algèbre');
    });

    test('clés sousRubriques/branches absentes -> listes vides (défensif)', () {
      final entity = DomaineResultatModel.fromJson(const {
        'rubriqueId': 'dom-x',
        'label': null,
        'produitSousTotal': false,
        'obtenu': 0.0,
        'max': 10.0,
        'pourcentage': null,
      }).toEntity();

      expect(entity.label, isNull);
      expect(entity.sousRubriques, isEmpty);
      expect(entity.branches, isEmpty);
    });
  });

  group('ResultatsClasseModel (vue classe)', () {
    final json = <String, dynamic>{
      'classroomId': 'class-1',
      'periodeScolaireId': 'per-1',
      'periodeOrdre': 1,
      'sousPeriodes': [
        {'sousPeriodeId': 'sp-1', 'ordre': 1, 'statut': 'CLOTUREE'},
        {'sousPeriodeId': 'sp-2', 'ordre': 2, 'statut': 'OUVERTE'},
      ],
      'stats': {
        'effectif': 2,
        'seuil': 50.0,
        'moyenneClasse': null,
        'reussites': 0,
        'echecs': 1,
        'nonClasses': 1,
        'best': null,
        'worst': null,
      },
      'lignes': [
        {
          'rang': 1,
          'studentId': 'stu-1',
          'nom': 'Doe',
          'postnom': 'K.',
          'prenom': 'Jane',
          'genre': 'FEMALE',
          'nonClasse': false,
          'pourcentages': [
            {'sousPeriodeId': 'sp-1', 'pourcentage': 42.0},
            {'sousPeriodeId': 'sp-2', 'pourcentage': null},
          ],
          'moyenneGroupe': 42.0,
        },
        {
          'rang': null,
          'studentId': 'stu-2',
          'nom': 'Roe',
          'postnom': null,
          'prenom': 'John',
          'genre': null,
          'nonClasse': true,
          'pourcentages': [
            {'sousPeriodeId': 'sp-1', 'pourcentage': null},
            {'sousPeriodeId': 'sp-2', 'pourcentage': null},
          ],
          'moyenneGroupe': null,
        },
      ],
    };

    test(
      'fromJson + toEntity : ordre conservé, nullable ≠ 0, enums mappés',
      () {
        final entity = ResultatsClasseModel.fromJson(json).toEntity();

        expect(entity.classroomId, 'class-1');
        expect(entity.periodeOrdre, 1);

        // Ordre des colonnes conservé + statut mappé.
        expect(entity.sousPeriodes.map((c) => c.sousPeriodeId), [
          'sp-1',
          'sp-2',
        ]);
        expect(entity.sousPeriodes[0].statut, StatutPeriode.cloturee);
        expect(entity.sousPeriodes[1].statut, StatutPeriode.ouverte);

        // Stats : aucun classé -> moyenne / best / worst null.
        expect(entity.stats.moyenneClasse, isNull);
        expect(entity.stats.best, isNull);
        expect(entity.stats.worst, isNull);
        expect(entity.stats.nonClasses, 1);

        // Ligne classée.
        final classee = entity.lignes.first;
        expect(classee.rang, 1);
        expect(classee.genre, ClassroomMemberGender.female);
        expect(classee.nonClasse, isFalse);
        // Cellule non notée conservée à null (≠ 0), alignée sur les colonnes.
        expect(classee.pourcentages[0].pourcentage, 42.0);
        expect(classee.pourcentages[1].pourcentage, isNull);

        // Ligne non classée (en fin) : rang / genre / moyenne null.
        final nonClassee = entity.lignes.last;
        expect(nonClassee.nonClasse, isTrue);
        expect(nonClassee.rang, isNull);
        expect(nonClassee.genre, isNull);
        expect(nonClassee.moyenneGroupe, isNull);
      },
    );
  });

  group('ResultatFocusModel (vue focus)', () {
    final json = <String, dynamic>{
      'classroomId': 'class-1',
      'periodeScolaireId': 'per-1',
      'periodeOrdre': 2,
      'entete': {
        'studentId': 'stu-1',
        'nom': 'Doe',
        'postnom': null,
        'prenom': 'Jane',
        'genre': 'MALE',
        'moyenneAnnuelle': null,
        'rang': null,
        'nbClasses': 20,
      },
      'progression': [
        {
          'sousPeriodeId': 'sp-1',
          'indexGlobal': 1,
          'periodeOrdre': 1,
          'sousPeriodeOrdre': 1,
          'pourcentage': null,
          'statut': 'OUVERTE',
          'dansGroupe': false,
        },
      ],
      'deltaPts': null,
      'topMatieres': [
        {'brancheId': 'br-1', 'brancheNom': 'Algèbre', 'pourcentage': 80.0},
      ],
      'bottomMatieres': [
        {'brancheId': 'br-2', 'brancheNom': 'Chimie', 'pourcentage': null},
      ],
      'bulletinParDomaine': null,
      'synthese': {
        'pourcentage': null,
        'place': null,
        'nbClasses': 20,
        'application': null,
        'conduite': null,
      },
    };

    test('bulletin null + synthese application/conduite null = cas valides', () {
      final entity = ResultatFocusModel.fromJson(json).toEntity();

      expect(entity.periodeOrdre, 2);
      expect(entity.entete.genre, ClassroomMemberGender.male);
      // Élève non classé : moyenne annuelle + rang null.
      expect(entity.entete.moyenneAnnuelle, isNull);
      expect(entity.entete.rang, isNull);

      expect(entity.progression.single.statut, StatutPeriode.ouverte);
      expect(entity.progression.single.pourcentage, isNull);
      expect(entity.progression.single.dansGroupe, isFalse);
      expect(entity.deltaPts, isNull);

      expect(entity.topMatieres.single.pourcentage, 80.0);
      expect(entity.bottomMatieres.single.pourcentage, isNull);

      // Élève non classé sur le groupe -> bulletin null (valide).
      expect(entity.bulletinParDomaine, isNull);
      // Application / conduite hors périmètre V1 -> null (valide, pas erreur).
      expect(entity.synthese.application, isNull);
      expect(entity.synthese.conduite, isNull);
      expect(entity.synthese.nbClasses, 20);
    });
  });
}
