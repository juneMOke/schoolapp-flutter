import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_list_report.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/repositories/hr_staff_dashboard_repository.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/usecases/hr_staff_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_list_report_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_stats_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_dashboard_page.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';

import '../hr_personnel_builders.dart';
import 'hr_personnel_harness.dart';

/// Un agent tel que le serveur le sert dans « Qui sont-ils ».
HrStaffMemberRow serverRow(
  String id, {
  String lastName = 'KALALA',
  String? middleName = 'Mutombo',
  String? firstName = 'Jean',
  StaffSex? sex = StaffSex.male,
  HrCategoryKey category = HrCategoryKey.teacher,
  String? jobTitle = 'Enseignant titulaire',
  String? entryDate = '2020-09-01',
  int? seniorityYears = 6,
  StaffContractKind? contractKind = StaffContractKind.permanent,
  HrDossierCount? dossier,
}) => HrStaffMemberRow(
  id: id,
  staffNumber: 'CF-AG-$id',
  lastName: lastName,
  middleName: middleName,
  firstName: firstName,
  sex: sex,
  category: category,
  jobTitle: jobTitle,
  entryDate: entryDate,
  seniorityYears: seniorityYears,
  contractKind: contractKind,
  dossier: dossier,
);

/// Les chiffres que le serveur aurait comptés sur [rows].
HrStaffStats statsOf(List<HrStaffMemberRow> rows) {
  HrSexSplit split(Iterable<HrStaffMemberRow> of) => HrSexSplit(
    women: of.where((r) => r.sex == StaffSex.female).length,
    men: of.where((r) => r.sex == StaffSex.male).length,
    unknown: of.where((r) => r.sex == null).length,
  );
  final dated = rows.where((r) => r.seniorityYears != null).toList();
  return HrStaffStats(
    asOf: '2026-10-24',
    headcount: rows.length,
    sexes: split(rows),
    averageSeniority: dated.isEmpty
        ? null
        : (dated.fold<int>(0, (sum, r) => sum + r.seniorityYears!) *
                      10 /
                      dated.length)
                  .round() /
              10,
    seniorityBase: dated.length,
    dean: null,
    categories: [
      for (final key in HrCategoryKey.values)
        if (rows.any((r) => r.category == key))
          HrCategoryCount(
            key: key,
            split: split(rows.where((r) => r.category == key)),
          ),
    ],
  );
}

/// Le serveur du tableau de bord, en mémoire : filtre (catégorie, mots du nom)
/// et trie par nom, puis découpe par pages de [pageSize]. Retient chaque
/// question posée.
class FakeHrStaffDashboard implements HrStaffDashboardRepository {
  List<HrStaffMemberRow> rows;
  HrStaffStats? statsOverride;

  /// Les chiffres ET la liste échouent.
  Failure? failure;

  /// La liste seule échoue : les chiffres, eux, arrivent.
  Failure? membersFailure;

  /// Le PDF échoue (429, 403, plafond…).
  Failure? reportFailure;
  final int pageSize;
  final List<(HrRosterQuery, int)> asked = [];
  final List<HrRosterQuery> printed = [];
  int statsCalls = 0;

  FakeHrStaffDashboard(this.rows, {this.pageSize = 20});

  @override
  Future<Either<Failure, HrStaffStats>> stats() async {
    statsCalls++;
    final failed = failure;
    if (failed != null) return Left(failed);
    return Right(statsOverride ?? statsOf(rows));
  }

  @override
  Future<Either<Failure, HrStaffMembersPage>> members(
    HrRosterQuery query, {
    required int page,
  }) async {
    asked.add((query, page));
    final failed = membersFailure ?? failure;
    if (failed != null) return Left(failed);
    final words = query.text
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty);
    final kept = [
      for (final row in rows)
        if ((query.category == null || row.category == query.category) &&
            words.every((w) => row.fullName.toLowerCase().contains(w)))
          row,
    ]..sort((a, b) => a.fullName.compareTo(b.fullName));
    final ordered = switch (query.sort) {
      HrRosterSort.name => kept,
      HrRosterSort.nameDescending => kept.reversed.toList(),
      // Date absente en fin de liste dans les deux sens, comme le serveur.
      HrRosterSort.oldest || HrRosterSort.newest => [
        ...kept.where((r) => r.entryDate != null).toList()..sort(
          (a, b) => query.sort == HrRosterSort.oldest
              ? a.entryDate!.compareTo(b.entryDate!)
              : b.entryDate!.compareTo(a.entryDate!),
        ),
        ...kept.where((r) => r.entryDate == null),
      ],
    };
    return Right(
      HrStaffMembersPage(
        totalElements: ordered.length,
        page: page,
        size: pageSize,
        items: ordered.skip(page * pageSize).take(pageSize).toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, HrStaffListReport>> report(HrRosterQuery query) async {
    printed.add(query);
    final failed = reportFailure;
    if (failed != null) return Left(failed);
    return Right(
      HrStaffListReport(
        bytes: Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]),
        fileName: 'personnel-20261024.pdf',
      ),
    );
  }
}

/// Monte le tableau de bord sur [server] et, pour ce qui n'est pas encore
/// parti, sur le fichier local [local].
Future<HrPersonnelCubit> pumpHrDashboard(
  WidgetTester tester, {
  required FakeHrStaffDashboard server,
  StaffFileSnapshot? local,
  Size? size = const Size(1280, 1400),
  MockStaffSnapshotSource? source,
}) {
  final stats = HrStaffStatsCubit(getStats: GetHrStaffStatsUseCase(server));
  final members = HrStaffMembersCubit(
    getMembers: GetHrStaffMembersUseCase(server),
    debounce: Duration.zero,
  );
  final report = HrStaffListReportCubit(
    getReport: GetHrStaffListReportUseCase(server),
  );
  addTearDown(stats.close);
  addTearDown(members.close);
  addTearDown(report.close);
  return pumpHrScreen(
    tester,
    snapshot: local ?? snapshotOf(const []),
    screen: const HrDashboardScreen(),
    size: size,
    source: source,
    extraProviders: [
      BlocProvider<HrStaffStatsCubit>.value(value: stats..load()),
      BlocProvider<HrStaffMembersCubit>.value(value: members..load()),
      BlocProvider<HrStaffListReportCubit>.value(value: report),
    ],
  );
}
