import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_classe_dto.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

import 'cote_fixture.dart';

void main() {
  test('lit la structure : découpage, arbre, sous-périodes', () {
    final classe = CoteClasseDto.fromJson(coteClasseJson()).toEntity();

    expect(classe.decoupage, Decoupage.semestre);
    expect(classe.periodes.single.sousPeriodes, hasLength(2));
    expect(
      classe.rubriques.first.sousRubriques.single.cours.single.branche,
      'EPS',
    );
    expect(classe.allCours.map((c) => c.coursId), ['fr', 'eps']);
    expect(classe.eleves.first.fullName, 'Mbaya Numbi Emmanuel');
  });

  test('un label nul reste nul : grille plate', () {
    final json = coteClasseJson();
    (json['rubriques'] as List).first['label'] = null;

    final classe = CoteClasseDto.fromJson(json).toEntity();

    expect(classe.rubriques.first.label, isNull);
  });

  test('une cellule : sa colonne vient de la sous-période ou de l\'examen', () {
    final dto = CoteClasseDto.fromJson(coteClasseJson());

    final periode = dto.cellules.firstWhere((c) => c.colonneId == 'P1');
    expect(periode.examen, isFalse);
    expect(periode.cote, 14.5);
    expect(periode.calculee, 13.25);
    final examen = dto.cellules.firstWhere((c) => c.colonneId == 'S1');
    expect(examen.examen, isTrue);
  });

  test('une cellule inutilisable est sautée, le reste passe', () {
    final json = coteClasseJson();
    (json['cellules'] as List).add({'studentId': 'e1'});
    (json['cellules'] as List).add('bruit');

    expect(CoteClasseDto.fromJson(json).cellules, hasLength(3));
  });

  test('une structure illisible lève : rien ne se placerait', () {
    final json = coteClasseJson();
    ((json['periodes'] as List).first as Map<String, dynamic>).remove('id');

    expect(() => CoteClasseDto.fromJson(json), throwsFormatException);
  });

  test(
    'la réponse peut taire la classe : l\'écran sait ce qu\'il a demandé',
    () {
      final json = coteClasseJson()..remove('classroomId');

      expect(() => CoteClasseDto.fromJson(json).toEntity(), returnsNormally);
    },
  );

  test('un cours sans maxExamen au fil vaut sans examen', () {
    final json = coteClasseJson();
    final rubrique = (json['rubriques'] as List).first as Map<String, dynamic>;
    ((rubrique['cours'] as List).first as Map<String, dynamic>).remove(
      'maxExamen',
    );

    final classe = CoteClasseDto.fromJson(json).toEntity();

    expect(classe.allCours.first.hasExamen, isFalse);
  });

  group('intitulés des colonnes', () {
    Map<String, dynamic> periode(Map<String, dynamic> json) =>
        (json['periodes'] as List).first as Map<String, dynamic>;

    test('un serveur ancien : ni nom ni avis sur l\'examen', () {
      final classe = CoteClasseDto.fromJson(coteClasseJson()).toEntity();

      final p = classe.periodes.single;
      expect(p.examen.exists, isTrue);
      expect(p.examen.intitule, isNull);
      expect(p.sousPeriodes.first.intitule, isNull);
    });

    test('les noms de la grille, et un examen nommé', () {
      final json = coteClasseJson();
      final p = periode(json);
      final sp = (p['sousPeriodes'] as List).first as Map<String, dynamic>;
      sp['libelle'] = 'Étape 3';
      sp['libelleCourt'] = 'É3';
      p['examen'] = {'libelle': 'Examen', 'libelleCourt': 'Exam.'};

      final classe = CoteClasseDto.fromJson(json).toEntity();

      final entity = classe.periodes.single;
      expect(entity.sousPeriodes.first.intitule?.libelle, 'Étape 3');
      expect(entity.sousPeriodes.first.intitule?.libelleCourt, 'É3');
      expect(entity.examen.exists, isTrue);
      expect(entity.examen.intitule?.libelleCourt, 'Exam.');
    });

    test('examen à null : la période n\'en a pas', () {
      final json = coteClasseJson();
      periode(json)['examen'] = null;

      final classe = CoteClasseDto.fromJson(json).toEntity();

      expect(classe.periodes.single.examen.exists, isFalse);
    });

    test('un seul des deux noms sert pour les deux', () {
      final json = coteClasseJson();
      final sp =
          (periode(json)['sousPeriodes'] as List).first as Map<String, dynamic>;
      sp['libelleCourt'] = ' É1 ';

      final intitule = CoteClasseDto.fromJson(
        json,
      ).toEntity().periodes.single.sousPeriodes.first.intitule;

      expect(intitule?.libelle, 'É1');
      expect(intitule?.libelleCourt, 'É1');
    });
  });
}
