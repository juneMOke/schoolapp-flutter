import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/student_name_comparator.dart';

/// Une identité minimale : ce que toute liste d'élèves porte, quel que soit le
/// module (le post-nom s'appelle `surname` côté inscription, `middleName` côté
/// classe et discipline — d'où le comparateur générique).
class _Person {
  final String lastName;
  final String? surname;
  final String firstName;
  final String id;

  const _Person(this.lastName, this.surname, this.firstName, {this.id = ''});
}

Comparator<_Person> get _comparator => StudentNameComparator.by<_Person>(
  lastName: (p) => p.lastName,
  surname: (p) => p.surname,
  firstName: (p) => p.firstName,
  id: (p) => p.id,
);

List<String> _sortedLastNames(List<_Person> people) =>
    ([...people]..sort(_comparator)).map((p) => p.lastName).toList();

void main() {
  group('StudentNameComparator — cascade Nom → Post-nom → Prénom', () {
    test('trie par nom en premier', () {
      expect(
        _sortedLastNames(const [
          _Person('Ndiaye', 'Mwamba', 'Awa'),
          _Person('Diop', 'Kalonji', 'Bob'),
          _Person('Kabongo', 'Tshibangu', 'Jean'),
        ]),
        ['Diop', 'Kabongo', 'Ndiaye'],
      );
    });

    test('à nom égal, départage par post-nom', () {
      final sorted = [
        ...const [
          _Person('Kabongo', 'Tshibangu', 'Awa'),
          _Person('Kabongo', 'Mwamba', 'Awa'),
        ],
      ]..sort(_comparator);
      expect(sorted.map((p) => p.surname), ['Mwamba', 'Tshibangu']);
    });

    test('à nom et post-nom égaux, départage par prénom', () {
      final sorted = [
        ...const [
          _Person('Kabongo', 'Mwamba', 'Zoe'),
          _Person('Kabongo', 'Mwamba', 'Awa'),
        ],
      ]..sort(_comparator);
      expect(sorted.map((p) => p.firstName), ['Awa', 'Zoe']);
    });
  });

  group('StudentNameComparator — accents et casse', () {
    test('un nom accentué se range à sa lettre, pas après Z', () {
      expect(
        _sortedLastNames(const [
          _Person('Zacharie', null, 'Paul'),
          _Person('Émile', null, 'Paul'),
        ]),
        ['Émile', 'Zacharie'],
        reason:
            'compareTo brut range « É » (201) après « Z » (90) : '
            "c'est le défaut que ce comparateur corrige",
      );
    });

    test('deux graphies du même nom restent voisines', () {
      expect(
        _sortedLastNames(const [
          _Person('Ilunga', null, 'Paul'),
          _Person('Jacques', null, 'Paul'),
          _Person('Îlunga', null, 'Paul'),
        ]),
        ['Ilunga', 'Îlunga', 'Jacques'],
        reason: 'un accent ne doit pas séparer deux homonymes par un tiers',
      );
    });

    test('la casse ne décide pas de l\'ordre', () {
      expect(
        _sortedLastNames(const [
          _Person('zola', null, 'Paul'),
          _Person('Mukendi', null, 'Paul'),
        ]),
        ['Mukendi', 'zola'],
        reason: 'sans repli de casse, toute minuscule passerait après « Z »',
      );
    });

    test('les espaces de bordure ne décident pas de l\'ordre', () {
      expect(
        _sortedLastNames(const [
          _Person('Mukendi', null, 'Paul'),
          _Person('  Kabongo', null, 'Paul'),
        ]),
        ['  Kabongo', 'Mukendi'],
      );
    });
  });

  group('StudentNameComparator — parties absentes', () {
    test('un nom vide ferme la marche', () {
      expect(
        _sortedLastNames(const [
          _Person('', null, 'Awa'),
          _Person('Ndiaye', null, 'Bob'),
          _Person('Diop', null, 'Zoe'),
        ]),
        ['Diop', 'Ndiaye', ''],
        reason:
            "intercaler un sans-nom au milieu de l'alphabet casserait "
            "précisément l'ordre qu'on vient y chercher",
      );
    });

    test('un post-nom absent passe après un post-nom renseigné', () {
      final sorted = [
        ...const [
          _Person('Kabongo', null, 'Awa'),
          _Person('Kabongo', 'Mwamba', 'Awa'),
        ],
      ]..sort(_comparator);
      expect(sorted.map((p) => p.surname), ['Mwamba', null]);
    });

    test(
      'deux parties absentes sont équivalentes : le rang suivant tranche',
      () {
        final sorted = [
          ...const [
            _Person('Kabongo', null, 'Zoe'),
            _Person('Kabongo', null, 'Awa'),
          ],
        ]..sort(_comparator);
        expect(sorted.map((p) => p.firstName), ['Awa', 'Zoe']);
      },
    );
  });

  group('StudentNameComparator — stabilité', () {
    test('deux homonymes complets sont départagés par identifiant', () {
      final sorted = [
        ...const [
          _Person('Kabongo', 'Mwamba', 'Awa', id: 'b'),
          _Person('Kabongo', 'Mwamba', 'Awa', id: 'a'),
        ],
      ]..sort(_comparator);
      expect(
        sorted.map((p) => p.id),
        ['a', 'b'],
        reason:
            "sans départage, l'ordre de deux fiches identiques dépendrait de "
            "leur ordre d'arrivée et la liste se réordonnerait toute seule",
      );
    });

    test(
      'le post-nom est facultatif : une forme sans post-nom saute ce rang',
      () {
        final comparator = StudentNameComparator.by<_Person>(
          lastName: (p) => p.lastName,
          firstName: (p) => p.firstName,
        );
        final sorted = [
          ...const [
            _Person('Kabongo', 'Tshibangu', 'Zoe'),
            _Person('Kabongo', 'Mwamba', 'Awa'),
          ],
        ]..sort(comparator);
        expect(
          sorted.map((p) => p.firstName),
          ['Awa', 'Zoe'],
          reason: 'le post-nom non déclaré ne doit pas peser sur l\'ordre',
        );
      },
    );
  });
}
