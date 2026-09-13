import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/referential_pull_models.dart';

/// La section `expenseTypes` du socle, lue depuis du **JSON brut** : une
/// fixture construite en Dart n'exerce jamais `fromJson`.
Map<String, dynamic> _bundle({Object? expenseTypes = _absent}) => {
  'school': {'id': 'sch-1', 'name': 'Ecole Etoile'},
  'current': {
    'academicYear': {'id': 'ay-1', 'name': '2026', 'isCurrent': true},
    'schoolLevelGroups': <Object>[],
    'schoolLevels': <Object>[],
  },
  'previous': null,
  if (!identical(expenseTypes, _absent)) 'expenseTypes': expenseTypes,
  'serverTime': '2026-09-13T08:00:00Z',
};

const Object _absent = Object();

Map<String, dynamic> _type({
  Object? id = 't-elec',
  Object? label = 'Électricité & eau',
  Object? shortLabel = 'Électricité',
  Object? active = true,
  Object? defaultCurrency = 'cdf',
}) => {
  'id': id,
  'code': 'electricite',
  'label': label,
  'shortLabel': shortLabel,
  'icon': 'power',
  'color': '#D9A24E',
  'softColor': '#FBF3E3',
  'defaultCurrency': defaultCurrency,
  'sortOrder': 0,
  'active': active,
};

void main() {
  test('section lue : code et devise normalisés, ordre gardé', () {
    final dto = ReferentialBundleDto.fromJson(
      _bundle(
        expenseTypes: [
          _type(),
          _type(id: 't-four', label: 'Fournitures', defaultCurrency: 'USD'),
        ],
      ),
    );

    final types = dto.expenseTypes!;
    expect(types.map((t) => t.id), ['t-elec', 't-four']);
    expect(types.first.code, 'ELECTRICITE');
    expect(types.first.defaultCurrency, 'CDF');
    expect(types.first.shortLabel, 'Électricité');
  });

  test('clé absente, nulle ou liste vide ⇒ null : le cache reste', () {
    expect(ReferentialBundleDto.fromJson(_bundle()).expenseTypes, isNull);
    expect(
      ReferentialBundleDto.fromJson(_bundle(expenseTypes: null)).expenseTypes,
      isNull,
    );
    expect(
      ReferentialBundleDto.fromJson(
        _bundle(expenseTypes: <Object>[]),
      ).expenseTypes,
      isNull,
    );
  });

  test('un type illisible est écarté sans emporter les autres', () {
    final dto = ReferentialBundleDto.fromJson(
      _bundle(
        expenseTypes: [
          _type(id: null),
          _type(label: '  '),
          'pas un objet',
          _type(id: 't-ok'),
        ],
      ),
    );

    expect(dto.expenseTypes!.map((t) => t.id), ['t-ok']);
  });

  test('replis : nom court absent → libellé, drapeau absent → actif', () {
    final type = RefExpenseTypeDto.tryParse(
      _type(shortLabel: null, active: null),
    )!;
    expect(type.shortLabel, 'Électricité & eau');
    expect(type.active, isTrue);
  });

  test('un type masqué descend quand même', () {
    final type = RefExpenseTypeDto.tryParse(_type(active: false))!;
    expect(type.active, isFalse);
  });
}
