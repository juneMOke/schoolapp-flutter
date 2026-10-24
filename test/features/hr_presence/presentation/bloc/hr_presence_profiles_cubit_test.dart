import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../../hr_presence_builders.dart';

class _MockGet extends Mock implements GetHrAttendanceProfilesUseCase {}

void main() {
  late _MockGet get;

  setUpAll(() => registerFallbackValue(const HrProfileScope.year()));

  setUp(() {
    get = _MockGet();
    when(() => get(any())).thenAnswer((_) async => Right(profilesOf()));
  });

  HrPresenceProfilesCubit build() {
    final cubit = HrPresenceProfilesCubit(
      getProfiles: get,
      yearStart: DateTime(2026, 9, 1),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  List<String> ids(HrPresenceProfilesState state) =>
      state.visibleRows.map((r) => r.agent.staffMemberId).toList();

  test('s\'ouvre sur le mois en cours ; l\'année relit le serveur', () async {
    final cubit = build();
    await cubit.load();
    verify(() => get(const HrProfileScope.month('2026-10'))).called(1);

    await cubit.setYearly(true);
    verify(() => get(const HrProfileScope.year())).called(1);
    // Le mois est gardé pour le retour à la vue mensuelle.
    expect(cubit.state.month, '2026-10');
  });

  test(
    'les puces comptent la sélection ; un second appui retire le filtre',
    () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.profileCounts, {
        PresenceProfile.absentee: 1,
        PresenceProfile.exemplary: 1,
        PresenceProfile.regular: 1,
      });

      cubit.toggleProfile(PresenceProfile.exemplary);
      expect(ids(cubit.state), ['a-2']);
      // Les comptes ne bougent pas avec la puce : ils disent la sélection.
      expect(cubit.state.profileCounts.length, 3);
      cubit.toggleProfile(PresenceProfile.exemplary);
      expect(ids(cubit.state), ['a-1', 'a-2', 'a-3']);
    },
  );

  test('recherche (nom, fonction, matricule) et catégorie', () async {
    final cubit = build();
    await cubit.load();
    cubit.setText('secretaire');
    expect(ids(cubit.state), ['a-1']);
    cubit.setText('AG-a-3');
    expect(ids(cubit.state), ['a-3']);
    cubit
      ..setText('')
      ..setCategory(StaffCategory.teacher);
    expect(ids(cubit.state), ['a-2', 'a-3']);
    expect(cubit.state.profileCounts.keys, [
      PresenceProfile.exemplary,
      PresenceProfile.regular,
    ]);
    cubit.clearFilters();
    expect(cubit.state.hasFilters, isFalse);
  });

  test('le mois ne passe ni le mois en cours ni la rentrée', () async {
    final cubit = build();
    await cubit.load();
    await cubit.stepMonth(1);
    expect(cubit.state.month, '2026-10');
    await cubit.stepMonth(-1);
    expect(cubit.state.month, '2026-09');
    expect(cubit.state.canStepBack, isFalse);
  });

  test('l\'adresse : l\'année, ou un mois lisible et permis', () async {
    final cubit = build();
    await cubit.load();
    await cubit.applyLocation(yearly: false, month: '2026-09');
    expect(cubit.state.month, '2026-09');
    await cubit.applyLocation(yearly: false, month: '2027-01');
    expect(cubit.state.month, '2026-10');
    await cubit.applyLocation(yearly: true);
    expect(cubit.state.yearly, isTrue);
  });
}
