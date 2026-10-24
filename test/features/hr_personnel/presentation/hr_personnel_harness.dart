import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockStaffSnapshotSource extends Mock implements StaffSnapshotSource {}

class MockAcademicYearContextBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class MockSchoolIdentityCubit extends MockCubit<SchoolIdentityState>
    implements SchoolIdentityCubit {}

/// Monte un écran RH · Personnel sur un fichier local donné, avec l'année
/// 2026-2027 et une école sans nom connu.
Future<HrPersonnelCubit> pumpHrScreen(
  WidgetTester tester, {
  required StaffFileSnapshot snapshot,
  required Widget screen,
  Size? size = const Size(1280, 1400),
  List<BlocProvider> extraProviders = const [],
  MockStaffSnapshotSource? source,
}) async {
  // `physicalSize`, pas `setSurfaceSize` : seul le premier change
  // `MediaQuery`. `null` : le format est déjà posé (test aux formats).
  if (size != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  // Une source fournie a déjà ses réponses.
  final mock = source ?? MockStaffSnapshotSource();
  if (source == null) {
    when(() => mock.watch(any())).thenReturn(() {});
    when(() => mock.pull()).thenAnswer((_) async {});
    when(() => mock.read()).thenAnswer((_) async => Right(snapshot));
  }

  final year = MockAcademicYearContextBloc();
  whenListen(
    year,
    const Stream<AcademicYearContextState>.empty(),
    initialState: const AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: AcademicYearContext(
        academicYear: AcademicYear(
          id: 'ay-1',
          name: '2026-2027',
          current: true,
        ),
        schoolLevelGroups: [],
      ),
    ),
  );
  final school = MockSchoolIdentityCubit();
  whenListen(
    school,
    const Stream<SchoolIdentityState>.empty(),
    initialState: const SchoolIdentityState.unknown(),
  );

  final cubit = HrPersonnelCubit(
    source: mock,
    now: () => DateTime(2026, 10, 24, 10),
  );
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AcademicYearContextBloc>.value(value: year),
        BlocProvider<SchoolIdentityCubit>.value(value: school),
        BlocProvider<HrPersonnelCubit>.value(value: cubit..load()),
        ...extraProviders,
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return cubit;
}
