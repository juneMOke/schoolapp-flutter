import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_list_report.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/usecases/hr_staff_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_list_report_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_stats_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_location_filters.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_staff_list_report_button.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

class _MockStats extends Mock implements GetHrStaffStatsUseCase {}

class _MockMembers extends Mock implements GetHrStaffMembersUseCase {}

class _MockReport extends Mock implements GetHrStaffListReportUseCase {}

HrStaffMembersPage _page(int total, {int page = 0}) => HrStaffMembersPage(
  totalElements: total,
  page: page,
  size: 20,
  items: const [],
);

const _stats = HrStaffStats(
  asOf: '2026-10-24',
  headcount: 3,
  sexes: HrSexSplit(women: 2, men: 1),
  averageSeniority: 9,
  seniorityBase: 3,
  dean: null,
  categories: [],
);

void main() {
  setUpAll(() => registerFallbackValue(HrRosterQuery.none));

  group('liste', () {
    late _MockMembers getMembers;
    late HrStaffMembersCubit cubit;

    setUp(() {
      getMembers = _MockMembers();
      when(
        () => getMembers(any(), page: any(named: 'page')),
      ).thenAnswer((_) async => Right(_page(42)));
      cubit = HrStaffMembersCubit(
        getMembers: getMembers,
        debounce: const Duration(milliseconds: 50),
      );
    });
    tearDown(() => cubit.close());

    test('la frappe attend sa fin : une seule question, la dernière', () async {
      cubit.setText('k');
      cubit.setText('ka');
      cubit.setText('kal');
      expect(cubit.state.query.text, 'kal');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      verify(
        () => getMembers(const HrRosterQuery(text: 'kal'), page: 0),
      ).called(1);
      verifyNoMoreInteractions(getMembers);
    });

    test('une réponse dépassée par un geste posé depuis est jetée', () async {
      final slow = Completer<Either<Failure, HrStaffMembersPage>>();
      when(
        () => getMembers(HrRosterQuery.none, page: 0),
      ).thenAnswer((_) => slow.future);
      final first = cubit.load();
      await cubit.setCategory(HrCategoryKey.teacher);
      slow.complete(Right(_page(99)));
      await first;

      expect(cubit.state.page!.totalElements, 42);
      expect(
        cubit.state.answered,
        const HrRosterQuery(category: HrCategoryKey.teacher),
      );
    });

    test('un critère changé repart de la première page', () async {
      await cubit.load();
      await cubit.pageChanged(1);
      await cubit.setSort(HrRosterSort.oldest);
      verify(
        () =>
            getMembers(const HrRosterQuery(sort: HrRosterSort.oldest), page: 0),
      ).called(1);
    });

    test('une page hors bornes ne part pas', () async {
      await cubit.load();
      clearInteractions(getMembers);
      await cubit.pageChanged(3); // 42 agents : pages 0 à 2
      await cubit.pageChanged(-1);
      verifyNever(() => getMembers(any(), page: any(named: 'page')));
    });

    test('une relecture ratée garde la page affichée', () async {
      await cubit.load();
      when(() => getMembers(any(), page: any(named: 'page'))).thenAnswer(
        (_) async => const Left(NetworkFailure('Aucune connexion.')),
      );
      await cubit.reload();
      expect(cubit.state.status, HrStaffMembersStatus.ready);
      expect(cubit.state.page!.totalElements, 42);
    });

    test('une première lecture ratée se dit, sans page', () async {
      when(() => getMembers(any(), page: any(named: 'page'))).thenAnswer(
        (_) async => const Left(NetworkFailure('Aucune connexion.')),
      );
      await cubit.load();
      expect(cubit.state.status, HrStaffMembersStatus.failure);
      expect(cubit.state.page, isNull);
      expect(cubit.state.answered, isNull);
    });

    test('l\'adresse pose catégorie et ordre ; la recherche reste', () async {
      cubit.setText('mayala');
      await cubit.applyLocation(
        const HrLocationFilters(
          category: HrCategoryKey.support,
          sort: HrRosterSort.newest,
          viewMode: CollectionViewMode.grid,
        ),
      );
      expect(
        cubit.state.query,
        const HrRosterQuery(
          text: 'mayala',
          category: HrCategoryKey.support,
          sort: HrRosterSort.newest,
        ),
      );
    });
  });

  group('chiffres', () {
    test('une relecture ratée garde les chiffres affichés', () async {
      final getStats = _MockStats();
      when(() => getStats()).thenAnswer((_) async => const Right(_stats));
      final cubit = HrStaffStatsCubit(getStats: getStats);
      addTearDown(cubit.close);
      await cubit.load();

      when(() => getStats()).thenAnswer(
        (_) async => const Left(NetworkFailure('Aucune connexion.')),
      );
      await cubit.load();
      expect(cubit.state.status, HrStaffStatsStatus.ready);
      expect(cubit.state.stats, _stats);
    });
  });

  group('PDF', () {
    final l10n = AppLocalizationsFr();

    test('un 429 désarme le bouton le temps annoncé', () async {
      final getReport = _MockReport();
      when(() => getReport(any())).thenAnswer(
        (_) async => const Left(
          TooManyRequestsFailure(retryAfter: Duration(milliseconds: 40)),
        ),
      );
      final cubit = HrStaffListReportCubit(getReport: getReport);
      addTearDown(cubit.close);

      await cubit.download(HrRosterQuery.none);
      expect(cubit.state.status, HrStaffListReportStatus.cooldown);
      await cubit.download(HrRosterQuery.none);
      verify(() => getReport(any())).called(1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cubit.state.status, HrStaffListReportStatus.idle);
    });

    test('le document se remet une fois, puis s\'oublie', () async {
      final getReport = _MockReport();
      when(() => getReport(any())).thenAnswer(
        (_) async => Right(
          HrStaffListReport(
            bytes: Uint8List.fromList(const [0x25]),
            fileName: 'personnel-20261024.pdf',
          ),
        ),
      );
      final cubit = HrStaffListReportCubit(getReport: getReport);
      addTearDown(cubit.close);

      await cubit.download(HrRosterQuery.none);
      expect(cubit.state.report, isNotNull);
      cubit.acknowledge();
      expect(cubit.state.hasDelivery, isFalse);
    });

    test('messages : 429, 403, plafond, défaut', () {
      expect(
        HrStaffListReportButton.message(
          const TooManyRequestsFailure(),
          const HrStaffListReportState(retryAfter: Duration(seconds: 30)),
          l10n,
        ),
        l10n.hrStaffReportBusy(30),
      );
      expect(
        HrStaffListReportButton.message(
          const UnauthorizedFailure(),
          const HrStaffListReportState(),
          l10n,
        ),
        l10n.hrStaffReportForbidden,
      );
      expect(
        HrStaffListReportButton.message(
          const ApiValidationFailure(
            code: ApiErrorCode.validation,
            detailCode: 'REPORT_LINE_CAP',
            details: {'lines': 7213, 'cap': 5000},
          ),
          const HrStaffListReportState(),
          l10n,
        ),
        l10n.hrStaffReportTooLarge(7213, 5000),
      );
      expect(
        HrStaffListReportButton.message(
          const ServerFailure(''),
          const HrStaffListReportState(),
          l10n,
        ),
        l10n.hrStaffReportFailed,
      );
    });
  });
}
