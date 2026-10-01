import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';

import '../../staff_builders.dart';

class _MockSource extends Mock implements StaffSnapshotSource {}

StaffFileSnapshot _snapshot({bool synced = true}) => StaffFileSnapshot(
  members: synced ? [member('m-1')] : const [],
  documentsByMember: const {},
  documentTypes: const [],
  hasEverSynced: synced,
);

void main() {
  late _MockSource source;
  late StaffFileCubit cubit;

  setUp(() {
    source = _MockSource();
    when(() => source.watch(any())).thenReturn(() {});
    when(() => source.pull()).thenAnswer((_) async {});
    cubit = StaffFileCubit(
      source: source,
      now: () => DateTime(2026, 9, 29, 10),
    );
  });
  tearDown(() => cubit.close());

  test('le jour se lit sans fuseau, en YYYY-MM-DD', () {
    expect(cubit.state.today, '2026-09-29');
  });

  test(
    'un fichier déjà descendu s affiche tout de suite, puis se tire',
    () async {
      when(() => source.read()).thenAnswer((_) async => Right(_snapshot()));

      await cubit.load();

      expect(cubit.state.status, StaffFileStatus.ready);
      expect(cubit.state.snapshot.members, hasLength(1));
      verify(() => source.pull()).called(1);
    },
  );

  test('jamais descendu : on attend le tirage avant de conclure', () async {
    final reads = [
      Right<Failure, StaffFileSnapshot>(_snapshot(synced: false)),
      Right<Failure, StaffFileSnapshot>(_snapshot()),
    ];
    when(() => source.read()).thenAnswer((_) async => reads.removeAt(0));

    await cubit.load();

    expect(cubit.state.status, StaffFileStatus.ready);
  });

  test('jamais descendu et le tirage échoue : prêt quand même', () async {
    when(
      () => source.read(),
    ).thenAnswer((_) async => Right(_snapshot(synced: false)));

    await cubit.load();

    // Hors ligne dès la première ouverture : le fichier local, même vide,
    // se lit et s'enrichit.
    expect(cubit.state.status, StaffFileStatus.ready);
    expect(cubit.state.snapshot.hasEverSynced, isFalse);
  });

  test('une base illisible est une panne, et on ne tire pas', () async {
    when(
      () => source.read(),
    ).thenAnswer((_) async => const Left(StorageFailure()));

    await cubit.load();

    expect(cubit.state.status, StaffFileStatus.failure);
    verifyNever(() => source.pull());
  });

  test('les filtres vivent dans l état, et se réinitialisent', () async {
    cubit
      ..setText('kal')
      ..setCategory(StaffCategory.teacher)
      ..toggleContract(StaffContractFilter.vacataire)
      ..toggleIncomplete()
      ..setViewMode(CollectionViewMode.list);

    expect(cubit.state.query.isActive, isTrue);
    expect(cubit.state.viewMode, CollectionViewMode.list);

    cubit.resetFilters();
    expect(cubit.state.query, StaffFileQuery.none);
    expect(cubit.state.viewMode, CollectionViewMode.list);
  });
}
