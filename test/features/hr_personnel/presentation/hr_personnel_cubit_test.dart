import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

import '../hr_personnel_builders.dart';

class _MockSource extends Mock implements StaffSnapshotSource {}

void main() {
  late _MockSource source;
  late HrPersonnelCubit cubit;

  setUp(() {
    source = _MockSource();
    when(() => source.watch(any())).thenReturn(() {});
    when(() => source.pull()).thenAnswer((_) async {});
    cubit = HrPersonnelCubit(
      source: source,
      now: () => DateTime(2026, 10, 24, 10),
    );
  });
  tearDown(() => cubit.close());

  test('un fichier déjà descendu est prêt aussitôt, puis se tire', () async {
    when(
      () => source.read(),
    ).thenAnswer((_) async => Right(snapshotOf([agent('a')])));

    await cubit.load();

    expect(cubit.state.status, HrPersonnelStatus.ready);
    expect(cubit.state.today, '2026-10-24');
    verify(() => source.pull()).called(1);
  });

  test(
    'jamais descendu et hors ligne : prêt quand même, sans erreur',
    () async {
      when(() => source.read()).thenAnswer(
        (_) async => Right(snapshotOf(const [], hasEverSynced: false)),
      );

      await cubit.load();

      expect(cubit.state.status, HrPersonnelStatus.ready);
      expect(cubit.state.snapshot.hasEverSynced, isFalse);
    },
  );

  test('une base illisible est une panne', () async {
    when(() => source.read()).thenAnswer(
      (_) async =>
          const Left<Failure, StaffFileSnapshot>(StorageFailure('illisible')),
    );

    await cubit.load();

    expect(cubit.state.status, HrPersonnelStatus.failure);
    verifyNever(() => source.pull());
  });

  test('la catégorie se pose puis se retire au second tap', () {
    cubit.toggleCategory(HrCategoryKey.administrative);
    expect(cubit.state.query.category, HrCategoryKey.administrative);

    cubit.toggleCategory(HrCategoryKey.administrative);
    expect(cubit.state.query.category, isNull);
  });

  test('l\'en-tête « Agent » alterne l\'ordre alphabétique', () {
    cubit.toggleNameOrder();
    expect(cubit.state.query.sort, HrRosterSort.nameDescending);

    cubit.toggleNameOrder();
    expect(cubit.state.query.sort, HrRosterSort.name);
  });

  test('« Tout afficher » vide recherche et catégorie, garde l\'ordre', () {
    cubit
      ..setText('kalala')
      ..setCategory(HrCategoryKey.teacher)
      ..setSort(HrRosterSort.oldest)
      ..clearFilters();

    expect(cubit.state.query, const HrRosterQuery(sort: HrRosterSort.oldest));
  });

  test('l\'affichage cartes / liste se garde dans l\'état', () {
    cubit.setViewMode(CollectionViewMode.list);
    expect(cubit.state.viewMode, CollectionViewMode.list);
  });

  test('une relecture silencieuse ne remet pas de squelette', () async {
    when(
      () => source.read(),
    ).thenAnswer((_) async => Right(snapshotOf([agent('a')])));
    await cubit.load();
    final states = <HrPersonnelStatus>[];
    final subscription = cubit.stream.listen((s) => states.add(s.status));

    await cubit.refresh();
    await subscription.cancel();

    expect(states, isNot(contains(HrPersonnelStatus.loading)));
  });
}
