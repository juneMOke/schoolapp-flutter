import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';

void main() {
  group('SearchNormalizationHelper.normalize', () {
    test('met en minuscules', () {
      expect(SearchNormalizationHelper.normalize('AWA'), 'awa');
    });

    test('retire les accents courants', () {
      expect(SearchNormalizationHelper.normalize('José'), 'jose');
      expect(SearchNormalizationHelper.normalize('Émile'), 'emile');
      expect(SearchNormalizationHelper.normalize('Noël'), 'noel');
      expect(SearchNormalizationHelper.normalize('François'), 'francois');
    });

    test('combine casse et accents', () {
      expect(SearchNormalizationHelper.normalize('ÉCOLE'), 'ecole');
    });

    test('laisse les caractères non accentués intacts', () {
      expect(SearchNormalizationHelper.normalize("N'Sumbu"), "n'sumbu");
    });
  });

  group('SearchNormalizationHelper.contains', () {
    test('terme vide ou null matche toujours', () {
      expect(SearchNormalizationHelper.contains('José', ''), isTrue);
      expect(SearchNormalizationHelper.contains('José', null), isTrue);
      expect(SearchNormalizationHelper.contains(null, null), isTrue);
    });

    test('champ null ne matche jamais un terme non vide', () {
      expect(SearchNormalizationHelper.contains(null, 'jose'), isFalse);
    });

    test('terme sans accent matche un champ accentué', () {
      expect(SearchNormalizationHelper.contains('José', 'jose'), isTrue);
    });

    test('terme accentué matche un champ sans accent', () {
      expect(SearchNormalizationHelper.contains('Ecole', 'écolé'), isTrue);
    });

    test('insensible à la casse', () {
      expect(SearchNormalizationHelper.contains('José', 'JOSE'), isTrue);
    });

    test('substring simple toujours supportée', () {
      expect(SearchNormalizationHelper.contains('Ndiaye', 'dia'), isTrue);
      expect(SearchNormalizationHelper.contains('Ndiaye', 'zzz'), isFalse);
    });
  });

  group('SearchNormalizationHelper.containsAny', () {
    // Une fiche type : nom KABONGO, post-nom Mwamba, prénom Jean.
    List<(String?, String?)> pairs({
      String? lastNameTerm,
      String? surnameTerm,
      String? firstNameTerm,
    }) => [
      ('Kabongo', lastNameTerm),
      ('Mwamba', surnameTerm),
      ('Jean', firstNameTerm),
    ];

    test('un seul critère satisfait suffit', () {
      expect(
        SearchNormalizationHelper.containsAny(pairs(firstNameTerm: 'jean')),
        isTrue,
      );
    });

    test('deux critères dont un seul satisfait → vrai (c\'est le OU)', () {
      expect(
        SearchNormalizationHelper.containsAny(
          pairs(lastNameTerm: 'kabongo', firstNameTerm: 'paul'),
        ),
        isTrue,
        reason: 'sous un ET, « paul » aurait éliminé la fiche',
      );
    });

    test('aucun critère satisfait → faux', () {
      expect(
        SearchNormalizationHelper.containsAny(
          pairs(lastNameTerm: 'zzz', firstNameTerm: 'yyy'),
        ),
        isFalse,
      );
    });

    test('chaque critère ne vise QUE sa propre valeur', () {
      expect(
        SearchNormalizationHelper.containsAny(pairs(firstNameTerm: 'kabongo')),
        isFalse,
        reason: '« Kabongo » est le nom, pas le prénom',
      );
    });

    test('aucun critère renseigné → vrai : un filtre sans critère ne retire '
        'personne', () {
      expect(SearchNormalizationHelper.containsAny(pairs()), isTrue);
      expect(
        SearchNormalizationHelper.containsAny(
          pairs(lastNameTerm: '   ', firstNameTerm: ''),
        ),
        isTrue,
        reason: 'des espaces ne sont pas un critère',
      );
      expect(SearchNormalizationHelper.containsAny(const []), isTrue);
    });

    test('valeur nulle : le critère ne matche pas, sans faire échouer les '
        'autres', () {
      expect(
        SearchNormalizationHelper.containsAny([
          (null, 'fatou'),
          ('Kabongo', 'kab'),
        ]),
        isTrue,
      );
      expect(SearchNormalizationHelper.containsAny([(null, 'fatou')]), isFalse);
    });

    test('reste insensible à la casse et aux accents', () {
      expect(
        SearchNormalizationHelper.containsAny([('Kabéya', 'kabeya')]),
        isTrue,
      );
    });
  });
}
