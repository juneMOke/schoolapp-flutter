import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';

/// L'ordre que l'école donne à ses sections, tel que l'état le porte.
///
/// Le DAO rend les titres rangés ; l'état en garde l'ordre des clés, et c'est
/// lui que les écrans suivent pour ranger les frais.
void main() {
  const state = FeeSectionTitlesState(
    titles: {
      'REGISTRATION': 'Frais d\'inscription',
      'TUITION': 'Frais scolaires annuels',
    },
  );

  test('le rang suit l\'ordre des titres', () {
    expect(state.rankOf('REGISTRATION'), 0);
    expect(state.rankOf('TUITION'), 1);
  });

  test('insensible à la casse et aux blancs, comme titleOf', () {
    expect(state.rankOf(' tuition '), 1);
  });

  test('une nature que l\'appareil ne connaît pas n\'a pas de rang', () {
    expect(state.rankOf('CANTEEN'), isNull);
    expect(const FeeSectionTitlesState().rankOf('TUITION'), isNull);
  });

  test('réordonner sans renommer CHANGE l\'état — sinon aucun écran ne se '
      'rebâtirait', () {
    const reordered = FeeSectionTitlesState(
      titles: {
        'TUITION': 'Frais scolaires annuels',
        'REGISTRATION': 'Frais d\'inscription',
      },
    );

    expect(reordered, isNot(state));
  });
}
