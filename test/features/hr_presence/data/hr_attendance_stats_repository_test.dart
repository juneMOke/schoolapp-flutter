import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' hide Headers;
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/hr_presence/data/hr_attendance_stats_api.dart';
import 'package:school_app_flutter/features/hr_presence/data/repositories/hr_attendance_stats_repository_impl.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import 'hr_attendance_fixtures.dart' as fx;

class _MockApi extends Mock implements HrAttendanceStatsApi {}

class _MockConnectivity extends Mock implements ConnectivityService {}

T _right<L, T>(dynamic either) =>
    either.fold((l) => throw StateError('échec : $l'), (r) => r) as T;

Failure? _left(dynamic either) =>
    either.fold((Failure f) => f, (_) => null) as Failure?;

void main() {
  late _MockApi api;
  late _MockConnectivity connectivity;
  late HrAttendanceStatsRepositoryImpl repo;
  final october = DashboardWindow(
    from: DateTime(2026, 10, 1),
    to: DateTime(2026, 10, 23),
  );

  setUpAll(() => registerFallbackValue(Options()));

  setUp(() {
    api = _MockApi();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    repo = HrAttendanceStatsRepositoryImpl(
      api: api,
      connectivity: connectivity,
      requiredAuth: const {'requiresAuth': true},
    );
  });

  group('tableau de bord', () {
    setUp(
      () => when(
        () => api.getDashboard(any(), any(), any()),
      ).thenAnswer((_) async => fx.dashboard()),
    );

    test('les bornes partent en AAAA-MM-JJ', () async {
      await repo.dashboard(october);
      verify(() => api.getDashboard(any(), '2026-10-01', '2026-10-23'));
    });

    test('le corps du DTO se lit en entier, lignes à plat', () async {
      final HrAttendanceDashboard dashboard = _right(
        await repo.dashboard(october),
      );
      expect(dashboard.classDays, 17);
      expect(dashboard.staffCount, 14);
      expect(dashboard.granularity, HrAttendanceGranularity.day);
      expect(dashboard.kpis.presenceRatePct, 91);
      expect(dashboard.kpis.absences, 4);
      expect(dashboard.series.last.isEmpty, isTrue);
      expect(dashboard.series.last.presenceRatePct, isNull);
      expect(dashboard.staff.first.agent.lastName, 'MWAMBA');
      expect(
        dashboard.staff.first.agent.category,
        StaffCategory.administrative,
      );
      expect(dashboard.staff.first.kpis.unjustifiedAbsences, 3);
      expect(dashboard.staff.last.kpis.presenceRatePct, isNull);
    });

    test('un compteur manquant fait échouer la lecture, pas un zéro', () async {
      when(
        () => api.getDashboard(any(), any(), any()),
      ).thenAnswer((_) async => fx.dashboard()..remove('classDays'));
      expect(_left(await repo.dashboard(october)), isA<ServerFailure>());
    });

    test('hors ligne : l’erreur réseau, sans appel', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);
      expect(_left(await repo.dashboard(october)), isA<NetworkFailure>());
      verifyNever(() => api.getDashboard(any(), any(), any()));
    });

    test('un 403 classé par l’intercepteur remonte tel quel', () async {
      when(() => api.getDashboard(any(), any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/hr/attendance-stats'),
          error: const UnauthorizedFailure(),
        ),
      );
      expect(_left(await repo.dashboard(october)), isA<UnauthorizedFailure>());
    });
  });

  group('agent', () {
    test('le mois : jours, incidents, tendance et profil', () async {
      when(
        () => api.getAgentMonth(any(), any(), any()),
      ).thenAnswer((_) async => fx.agentMonth());
      final month = _right(await repo.agentMonth('a-1', month: '2026-10'));
      verify(() => api.getAgentMonth(any(), 'a-1', '2026-10'));
      expect(month.profile, PresenceProfile.absentee);
      expect(month.days.first.status, PresenceStatus.late);
      expect(month.days.first.reason, StaffAbsenceReason.transport);
      expect(month.days.first.arrival, '07:52');
      expect(month.days.last.future, isTrue);
      expect(month.incidents.map((d) => d.date), ['2026-10-01']);
      expect(month.trend.last.presenceRatePct, 78);
    });

    test('l’année : mois de classe ouvrables, mois futurs fermés', () async {
      when(
        () => api.getAgentYear(any(), any()),
      ).thenAnswer((_) async => fx.agentYear());
      final year = _right(await repo.agentYear('a-1'));
      expect(year.schoolYear.name, '2026-2027');
      expect(year.months.first.isOpenable, isTrue);
      expect(year.months.last.state, HrAttendanceMonthState.future);
      expect(year.months.last.isOpenable, isFalse);
      expect(year.months.last.profile, PresenceProfile.notEvaluated);
    });
  });

  group('fiche individuelle', () {
    setUp(
      () => when(
        () => api.getProfiles(any(), any(), any()),
      ).thenAnswer((_) async => fx.profiles()),
    );

    test('sur un mois : month seul, sans scope', () async {
      await repo.profiles(const HrProfileScope.month('2026-10'));
      verify(() => api.getProfiles(any(), '2026-10', any(that: isNull)));
    });

    test('sur l’année : scope=year seul, sans month', () async {
      await repo.profiles(const HrProfileScope.year());
      verify(() => api.getProfiles(any(), any(that: isNull), 'year'));
    });

    test('un profil absent des comptes se compte zéro', () async {
      final HrAttendanceProfiles profiles = _right(
        await repo.profiles(const HrProfileScope.month('2026-10')),
      );
      expect(profiles.profileCounts[PresenceProfile.exemplary], 5);
      expect(profiles.profileCounts[PresenceProfile.notEvaluated], 0);
      expect(profiles.staff.single.profile, PresenceProfile.absentee);
      expect(profiles.staff.single.absenceRatePct, 21);
    });
  });

  group('récapitulatif', () {
    test('montants par devise sous hr.pay.read', () async {
      when(
        () => api.getRecap(any(), any()),
      ).thenAnswer((_) async => fx.recap());
      final recap = _right(await repo.recap('2026-10'));
      expect(recap.totals.amounts, [const Money(36800, 'USD')]);
      expect(recap.staff.single.agent.isHourly, isTrue);
      expect(recap.staff.single.amount, const Money(16000, 'USD'));
      expect(recap.closable, isFalse);
      expect(recap.staff.single.unscored, 0);
    });

    test('sans hr.pay.read : aucun montant', () async {
      when(
        () => api.getRecap(any(), any()),
      ).thenAnswer((_) async => fx.recap(withAmounts: false));
      final recap = _right(await repo.recap('2026-10'));
      expect(recap.totals.amounts, isNull);
      expect(recap.staff.single.amount, isNull);
    });
  });

  group('PDF', () {
    HttpResponse<Uint8List> pdf() => HttpResponse(
      Uint8List.fromList('%PDF-1.7'.codeUnits),
      Response(
        requestOptions: RequestOptions(path: '/api/v1/hr/attendance-stats.pdf'),
        statusCode: 200,
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['application/pdf'],
          'content-disposition': ['attachment; filename="AP-2026-0001.pdf"'],
        }),
      ),
    );

    setUp(
      () => when(
        () => api.getReport(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => pdf()),
    );

    test('une recherche blanche ne part pas', () async {
      await repo.report(october, search: '   ');
      verify(
        () => api.getReport(
          any(),
          '2026-10-01',
          '2026-10-23',
          any(that: isNull),
          any(),
        ),
      );
    });

    test('la recherche part telle que saisie, sans ses blancs', () async {
      final report = _right(await repo.report(october, search: ' kalala '));
      verify(() => api.getReport(any(), any(), any(), 'kalala', any()));
      expect(report.fileName, 'AP-2026-0001.pdf');
    });

    test('hors ligne : l’erreur réseau, sans rendu demandé', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);
      expect(_left(await repo.report(october)), isA<NetworkFailure>());
      verifyNever(() => api.getReport(any(), any(), any(), any(), any()));
    });
  });
}
