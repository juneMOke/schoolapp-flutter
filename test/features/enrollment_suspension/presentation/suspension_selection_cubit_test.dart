import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_selection_cubit.dart';

void main() {
  test('hors mode sélection, rien ne se coche', () {
    final cubit = SuspensionSelectionCubit()..toggle('e1');
    expect(cubit.state.selected, isEmpty);
  });

  test('la sélection survit, puis se vide à l\'annulation', () {
    final cubit = SuspensionSelectionCubit()
      ..start()
      ..toggle('e1')
      ..togglePage(['e2', 'e3']);
    expect(cubit.state.selected, {'e1', 'e2', 'e3'});
    cubit.cancel();
    expect(cubit.state.active, isFalse);
    expect(cubit.state.selected, isEmpty);
  });

  test('une nouvelle recherche élague ce qu\'on ne voit plus', () {
    final cubit = SuspensionSelectionCubit()
      ..start()
      ..togglePage(['e1', 'e2', 'e3'])
      ..retain({'e2', 'e9'});
    expect(cubit.state.selected, {'e2'});
    expect(cubit.state.active, isTrue);
  });
}
