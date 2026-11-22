import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/helpers/client_side_paginator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'recouvrement_shots.dart';

class _Bloc extends MockBloc<FeeControlEvent, FeeControlState>
    implements FeeControlBloc {}

class _Year extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _Titles extends Cubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {
  _Titles()
    : super(
        const FeeSectionTitlesState(
          titles: {
            'REGISTRATION': 'Inscription',
            'TUITION': 'Scolarité',
            'SUPPLIES': 'Fournitures',
            'ACTIVITIES': 'Activités',
          },
        ),
      );

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _names = [
  ('Banza', 'Kasongo', 'Josué'),
  ('Ilunga', 'Ntumba', 'Grâce'),
  ('Kalonji', 'Wembo', 'Emmanuel'),
  ('Kapinga', 'Kasongo', 'Michel'),
  ('Kasenda', 'Kalala', 'Patrick'),
  ('Kasenda', 'Lwanga', 'Patrick'),
  ('Kasenda', 'Nsimba', 'Sarah'),
  ('Kayembe', 'Nsimba', 'Nathalie'),
  ('Kayembe', 'Ntumba', 'Michel'),
  ('Kayembe', 'Wembo', 'Michel'),
  ('Lukusa', 'Mbuyi', 'Esther'),
  ('Mbala', 'Kanku', 'Divine'),
  ('Mujinga', 'Tshiala', 'Ruth'),
  ('Ngoy', 'Muteba', 'Serge'),
  ('Nkulu', 'Bakonga', 'Daniel'),
  ('Tshala', 'Mwamba', 'Bénédicte'),
];

/// 1ère primaire, scolarité 240 $ : 24 rien, 5 partiels, 11 soldés.
List<FeeControlRow> _rows() {
  final rows = <FeeControlRow>[];
  for (var i = 0; i < 40; i++) {
    final n = _names[i % _names.length];
    final paid = i < 24 ? 0 : (i < 29 ? 12000 : 24000);
    rows.add(
      FeeControlRow(
        summary: EnrollmentSummary(
          enrollmentId: 'e$i',
          enrollmentCode: 'E-0${100 + i}',
          status: 'COMPLETED',
          syncState: SyncState.synced,
          student: StudentSummary(
            id: 's$i',
            firstName: n.$3,
            lastName: n.$1,
            surname: n.$2,
            dateOfBirth: '2018-01-01',
            gender: i.isEven ? Gender.male : Gender.female,
          ),
        ),
        line: LocalRecoveryLine(
          schoolLevelId: 'p1',
          studentId: 's$i',
          charges: [
            RecoveryChargePosition(
              feeCode: 'TUITION',
              position: FeeChargePosition(
                currency: 'USD',
                expectedInCents: 24000,
                paidMirrorInCents: paid,
                paidPendingInCents: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
  return FeeControlProjector.refilter(
    rows,
    filter: FeeControlPaymentFilter.all,
    mixed: false,
  );
}

FeeControlState _state() {
  final rows = _rows();
  const query = FeeControlQuery(
    academicYearId: 'ay',
    classroomId: 'c-p1',
    feeCodes: ['TUITION'],
    statusFilter: FeeControlPaymentFilter.all,
    page: 0,
    size: 10,
  );
  return const FeeControlState()
      .withPage(
        query: query,
        page: ClientSidePaginator.paginate(rows, page: 0, size: 10),
        studentsInScope: 40,
        breakdown: const FeeControlBreakdown(settled: 11, partial: 5, none: 24),
        expected: MoneyBag.of([Money.parse(960000, 'USD')]),
        collected: MoneyBag.of([Money.parse(312600, 'USD')]),
        currencies: const {'USD'},
        classroomRosterSize: 40,
      )
      .copyWith(
        catalogStatus: EnrollmentLoadStatus.success,
        natures: const [
          FeeNature(feeCode: 'TUITION', currencies: ['USD']),
          FeeNature(feeCode: 'REGISTRATION', currencies: ['CDF']),
          FeeNature(feeCode: 'SUPPLIES', currencies: ['USD']),
          FeeNature(feeCode: 'ACTIVITIES', currencies: ['USD']),
        ],
        classrooms: const [
          OfflineClassroom(
            id: 'c-p1',
            academicYearId: 'ay',
            schoolLevelGroupId: 'g-p',
            schoolLevelId: 'p1',
            name: '1ère primaire',
          ),
        ],
      );
}

void main() {
  setUpAll(loadRealFonts);

  testWidgets('captures du contrôle des frais', (tester) async {
    final bloc = _Bloc();
    final year = _Year();
    final auth = _Auth();
    whenListen(
      bloc,
      const Stream<FeeControlState>.empty(),
      initialState: _state(),
    );
    whenListen(
      year,
      const Stream<AcademicYearContextState>.empty(),
      initialState: AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'ay',
            name: '2026-2027',
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2027, 7, 1),
            current: true,
          ),
          schoolLevelGroups: const [
            SchoolLevelGroupBundle(
              group: SchoolLevelGroup(
                id: 'g-p',
                name: 'Primaire',
                code: 'P',
                displayOrder: 2,
              ),
              levels: [
                SchoolLevel(
                  id: 'p1',
                  name: '1ère primaire',
                  code: 'P1',
                  displayOrder: 1,
                  splitIntoClassrooms: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.authenticated),
    );
    GetIt.instance
      ..registerFactory<FeeControlBloc>(() => bloc)
      ..registerFactory<FeeSectionTitlesCubit>(_Titles.new);

    Widget app() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AcademicYearContextBloc>.value(value: year),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: const Scaffold(
          body: FeeControlPage(
            intent: FeeControlIntent(
              classroomId: 'c-p1',
              feeCodes: ['TUITION'],
            ),
          ),
        ),
      ),
    );

    for (final (name, size, full) in const [
      ('cf-1280', Size(1148, 800), 1500.0),
      ('cf-800', Size(668, 1280), 1900.0),
      ('cf-360', Size(328, 740), 2600.0),
    ]) {
      await shoot(tester, name, size, app(), fullPageHeight: full);
    }
    await GetIt.instance.reset();
  });
}
