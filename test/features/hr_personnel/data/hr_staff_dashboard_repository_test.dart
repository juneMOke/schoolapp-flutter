import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' hide Headers;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/hr_personnel/data/hr_staff_dashboard_api.dart';
import 'package:school_app_flutter/features/hr_personnel/data/repositories/hr_staff_dashboard_repository_impl.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

class _MockApi extends Mock implements HrStaffDashboardApi {}

class _MockConnectivity extends Mock implements ConnectivityService {}

/// `StaffStatsDto` tel que le swagger du back le décrit
/// (`feat/hr-staff-dashboard`, 2026-10-24).
Map<String, dynamic> _stats() => {
  'asOf': '2026-10-24',
  'headcount': 42,
  'sexes': {'women': 19, 'men': 21, 'unknown': 2},
  'seniority': {'average': 7.4, 'base': 39},
  'dean': {
    'staffMemberId': 'd-1',
    'lastName': 'MBUYI',
    'middleName': 'KABEYA',
    'firstName': 'Béatrice',
    'entryDate': '1998-09-01',
    'years': 28,
  },
  'categories': [
    {'category': 'ENSEIGNANT', 'women': 12, 'men': 15, 'unknown': 2},
    {'category': 'ADMINISTRATIF', 'women': 5, 'men': 3, 'unknown': 0},
    {'category': 'APPUI', 'women': 2, 'men': 3, 'unknown': 0},
  ],
};

/// `StaffMemberPageDto` : un agent complet, un agent aux champs nuls et sans
/// `dossier` (appelant sans `hr.document.read`).
Map<String, dynamic> _page() => {
  'totalElements': 42,
  'page': 0,
  'size': 20,
  'items': [
    {
      'id': 'a-1',
      'staffNumber': 'CF-AG-0012',
      'lastName': 'MBUYI',
      'middleName': 'KABEYA',
      'firstName': 'Béatrice',
      'sex': 'F',
      'category': 'ENSEIGNANT',
      'jobTitle': 'Professeure de français',
      'entryDate': '1998-09-01',
      'seniorityYears': 28,
      'contractKind': 'PERMANENT',
      'dossier': {'provided': 3, 'required': 4},
    },
    {
      'id': 'a-2',
      'staffNumber': 'CF-AG-0013',
      'lastName': 'KALALA',
      'middleName': null,
      'firstName': null,
      'sex': null,
      'category': 'APPUI',
      'jobTitle': null,
      'entryDate': null,
      'seniorityYears': null,
      'contractKind': null,
    },
  ],
};

void main() {
  late _MockApi api;
  late _MockConnectivity connectivity;
  late HrStaffDashboardRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(Options()));

  setUp(() {
    api = _MockApi();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    repo = HrStaffDashboardRepositoryImpl(
      api: api,
      connectivity: connectivity,
      requiredAuth: const {'requiresAuth': true},
    );
  });

  void stubMembers(Future<Map<String, dynamic>> Function() answer) => when(
    () => api.getMembers(any(), any(), any(), any(), any(), any()),
  ).thenAnswer((_) => answer());

  group('chiffres', () {
    test('le corps du swagger se lit en entier', () async {
      when(() => api.getStats(any())).thenAnswer((_) async => _stats());
      final stats = (await repo.stats()).getOrElse(
        () => throw StateError('échec'),
      );

      expect(stats.asOf, '2026-10-24');
      expect(stats.headcount, 42);
      expect(stats.sexes, const HrSexSplit(women: 19, men: 21, unknown: 2));
      expect(stats.averageSeniority, 7.4);
      expect(stats.seniorityBase, 39);
      expect(stats.dean!.displayName, 'Béatrice MBUYI');
      expect(stats.dean!.years, 28);
      expect(stats.categories.map((c) => c.key), [
        HrCategoryKey.teacher,
        HrCategoryKey.administrative,
        HrCategoryKey.support,
      ]);
      expect(stats.teachers, 29);
    });

    test('une école sans agent : zéros, ni moyenne ni doyen', () async {
      when(() => api.getStats(any())).thenAnswer(
        (_) async => {
          ..._stats(),
          'headcount': 0,
          'sexes': {'women': 0, 'men': 0, 'unknown': 0},
          'seniority': {'average': null, 'base': 0},
          'dean': null,
          'categories': <Object>[],
        },
      );
      final stats = (await repo.stats()).getOrElse(
        () => throw StateError('échec'),
      );
      expect(stats.averageSeniority, isNull);
      expect(stats.dean, isNull);
      expect(stats.categories, isEmpty);
    });

    test(
      'une catégorie que ce poste ne connaît pas se compte à part',
      () async {
        when(() => api.getStats(any())).thenAnswer(
          (_) async => {
            ..._stats(),
            'categories': [
              {'category': 'STAGIAIRE', 'women': 1, 'men': 0, 'unknown': 0},
            ],
          },
        );
        final stats = (await repo.stats()).getOrElse(
          () => throw StateError('échec'),
        );
        expect(stats.categories.single.key, HrCategoryKey.unknown);
      },
    );

    test('un compteur manquant fait échouer la lecture, pas un zéro', () async {
      when(
        () => api.getStats(any()),
      ).thenAnswer((_) async => {..._stats()}..remove('headcount'));
      final result = await repo.stats();
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });

    test('hors ligne : l\'erreur réseau, sans appel', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);
      final result = await repo.stats();
      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      verifyNever(() => api.getStats(any()));
    });

    test('un 403 classé par l\'intercepteur remonte tel quel', () async {
      when(() => api.getStats(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/hr/staff-stats'),
          error: const UnauthorizedFailure(),
        ),
      );
      final result = await repo.stats();
      expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
    });
  });

  group('liste', () {
    test('sans critère : seuls l\'ordre et la page partent', () async {
      stubMembers(() async => _page());
      await repo.members(HrRosterQuery.none, page: 0);
      verify(
        () => api.getMembers(
          any(),
          any(that: isNull),
          any(that: isNull),
          'NAME',
          0,
          20,
        ),
      ).called(1);
    });

    test('recherche nettoyée, catégorie et ordre sur le fil', () async {
      stubMembers(() async => _page());
      await repo.members(
        const HrRosterQuery(
          text: '  kalala ',
          category: HrCategoryKey.support,
          sort: HrRosterSort.newest,
        ),
        page: 2,
      );
      verify(
        () => api.getMembers(any(), 'kalala', 'APPUI', 'NEWEST', 2, 20),
      ).called(1);
    });

    test('« non renseignée » ne part jamais : le serveur la refuse', () async {
      stubMembers(() async => _page());
      await repo.members(
        const HrRosterQuery(
          category: HrCategoryKey.unknown,
          sort: HrRosterSort.nameDescending,
        ),
        page: 0,
      );
      verify(
        () => api.getMembers(
          any(),
          any(that: isNull),
          any(that: isNull),
          'NAME_DESC',
          0,
          20,
        ),
      ).called(1);
    });

    test('la page se lit, champs nuls et dossier absent compris', () async {
      stubMembers(() async => _page());
      final page = (await repo.members(
        HrRosterQuery.none,
        page: 0,
      )).getOrElse(() => throw StateError('échec'));

      expect(page.totalPages, 3);
      final full = page.items.first;
      expect(full.fullName, 'MBUYI KABEYA Béatrice');
      expect(full.sex, StaffSex.female);
      expect(full.category, HrCategoryKey.teacher);
      expect(full.contractKind, StaffContractKind.permanent);
      expect(full.dossier, const HrDossierCount(provided: 3, required: 4));
      final bare = page.items.last;
      expect(bare.fullName, 'KALALA');
      expect(bare.sex, isNull);
      expect(bare.seniorityYears, isNull);
      expect(bare.contractKind, isNull);
      expect(bare.dossier, isNull);
    });

    test('une ligne illisible fait échouer la page', () async {
      stubMembers(
        () async => {
          ..._page(),
          'items': [
            {'id': 'a-1', 'lastName': 'MBUYI'},
          ],
        },
      );
      final result = await repo.members(HrRosterQuery.none, page: 0);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });

  group('PDF', () {
    HttpResponse<Uint8List> pdf(List<int> bytes, {String? type}) {
      final options = RequestOptions(
        path: '/api/v1/hr/staff-stats/members.pdf',
      );
      return HttpResponse(
        Uint8List.fromList(bytes),
        Response(
          requestOptions: options,
          headers: Headers.fromMap({
            Headers.contentTypeHeader: [type ?? 'application/pdf'],
            'content-disposition': [
              'attachment; filename="personnel-enseignant-20261024.pdf"',
            ],
          }),
        ),
      );
    }

    void stubReport(Future<HttpResponse<Uint8List>> Function() answer) => when(
      () => api.getMembersReport(any(), any(), any(), any(), any()),
    ).thenAnswer((_) => answer());

    test(
      'la même question que la liste, sans page, délai de rapport',
      () async {
        stubReport(() async => pdf([0x25, 0x50, 0x44, 0x46, 0x2d]));
        final report = (await repo.report(
          const HrRosterQuery(
            text: 'mbuyi',
            category: HrCategoryKey.teacher,
            sort: HrRosterSort.oldest,
          ),
        )).getOrElse(() => throw StateError('échec'));

        expect(report.fileName, 'personnel-enseignant-20261024.pdf');
        final options =
            verify(
                  () => api.getMembersReport(
                    any(),
                    'mbuyi',
                    'ENSEIGNANT',
                    'OLDEST',
                    captureAny(),
                  ),
                ).captured.single
                as Options;
        expect(options.receiveTimeout, const Duration(seconds: 60));
      },
    );

    test('un 200 qui n\'est pas un PDF est refusé', () async {
      stubReport(() async => pdf('<html>'.codeUnits, type: 'text/html'));
      final result = await repo.report(HrRosterQuery.none);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
