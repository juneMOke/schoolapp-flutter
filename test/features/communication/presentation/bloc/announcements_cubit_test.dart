import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/owner_scoped_value.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_state.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementRepository {}

void main() {
  late _MockRepository repository;
  late OwnerScopedValue<AnnouncementFilters> memory;
  var owner = 'u1@s1';

  setUp(() {
    repository = _MockRepository();
    owner = 'u1@s1';
    memory = OwnerScopedValue(const AnnouncementFilters(), owner: () => owner);
  });

  AnnouncementsCubit cubit() =>
      AnnouncementsCubit(repository: repository, memory: memory);

  test('charge l\'année demandée, puis la rejoue sur « Réessayer »', () async {
    when(
      () => repository.list(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => Right([announcement()]));
    final c = cubit();
    await c.load(academicYearId: 'y-1');
    expect(c.state.status, AnnouncementsStatus.ready);
    expect(c.state.items, hasLength(1));
    await c.load();
    verify(() => repository.list(academicYearId: 'y-1')).called(2);
  });

  test('échec : l\'état le porte', () async {
    when(
      () => repository.list(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final c = cubit();
    await c.load();
    expect(c.state.status, AnnouncementsStatus.failure);
    expect(c.state.failure, const NetworkFailure());
  });

  test('les filtres survivent à un nouveau cubit, pas à un autre compte', () {
    cubit()
      ..toggleStatus(AnnouncementStatus.sent)
      ..toggleCategory(AnnouncementCategory.urgent)
      ..setQuery('pluie');
    expect(cubit().state.filters.activeCount, 3);
    owner = 'u2@s1';
    expect(cubit().state.filters.isActive, isFalse);
  });

  test('re-cocher un statut le retire ; Effacer remet tout à zéro', () {
    final c = cubit()
      ..toggleStatus(AnnouncementStatus.sent)
      ..toggleStatus(AnnouncementStatus.sent);
    expect(c.state.filters.statuses, isEmpty);
    c
      ..setQuery('x')
      ..clearFilters();
    expect(c.state.filters, const AnnouncementFilters());
  });

  test('upsert remplace en place ; un annulé quitte la liste', () async {
    when(
      () => repository.list(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer(
      (_) async => Right([announcement(id: 'a'), announcement(id: 'b')]),
    );
    final c = cubit();
    await c.load();
    c.upsert(announcement(id: 'b', title: 'Nouveau titre'));
    expect(c.state.items.first.content.title, 'Nouveau titre');
    expect(c.state.items, hasLength(2));
    c.upsert(announcement(id: 'a', status: AnnouncementStatus.cancelled));
    expect(c.state.items.map((a) => a.id), ['b']);
  });
}
