import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/register/class_presence_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_commands.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/pages/class_presence_page.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'class_presence_fixtures.dart';

class _Years
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _Classes extends MockBloc<ClassroomOfflineEvent, ClassroomOfflineState>
    implements ClassroomOfflineBloc {}

class _Load extends Mock implements LoadClassPresenceDayUseCase {}

class _LoadMonth extends Mock implements LoadClassPresenceMonthUseCase {}

class _Signals extends Mock implements ResourceSyncSignals {}

void main() {
  setUpAll(() {
    registerFallbackValue(const (classroomId: '', academicYearId: '', day: ''));
    registerFallbackValue(const (
      classroomId: '',
      academicYearId: '',
      month: '',
    ));
    registerFallbackValue(const AcademicYearContextRequested());
  });

  testWidgets(
    'choisir la classe, ouvrir le récapitulatif, puis la fiche d un élève',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final yearState = const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'y1',
            name: '2026-2027',
            current: true,
          ),
          schoolLevelGroups: [
            SchoolLevelGroupBundle(
              group: SchoolLevelGroup(
                id: 'g1',
                name: 'Primaire',
                code: 'P',
                displayOrder: 1,
              ),
              levels: [
                SchoolLevel(
                  id: 'l6',
                  name: '6ème primaire',
                  code: 'P6',
                  displayOrder: 6,
                  splitIntoClassrooms: true,
                ),
              ],
            ),
          ],
        ),
      );
      final years = _Years();
      when(() => years.state).thenReturn(yearState);
      whenListen(
        years,
        const Stream<AcademicYearContextState>.empty(),
        initialState: yearState,
      );
      final classes = _Classes();
      const classState = ClassroomOfflineState(
        classrooms: [
          OfflineClassroom(
            id: 'c1',
            academicYearId: 'y1',
            schoolLevelId: 'l6',
            name: '6e A',
            totalCount: 3,
          ),
        ],
      );
      when(() => classes.state).thenReturn(classState);
      whenListen(
        classes,
        const Stream<ClassroomOfflineState>.empty(),
        initialState: classState,
      );

      final load = _Load();
      when(() => load(any())).thenAnswer((_) async => Right(presenceDay()));
      final loadMonth = _LoadMonth();
      when(() => loadMonth(any())).thenAnswer(
        (_) async => Right(
          ClassPresenceMonth(
            classroomId: 'c1',
            academicYearId: 'y1',
            month: '2026-10',
            students: [grace, jean, esther],
            calledDays: const {'2026-10-01'},
            incidents: {
              '2026-10-01': {'s2': line(jean, PresenceStatus.absent)},
            },
          ),
        ),
      );
      final signals = _Signals();
      when(() => signals.watch(any())).thenReturn(() {});
      when(signals.pull).thenAnswer((_) async {});
      final cubit = ClassPresenceCubit(
        load: load,
        loadMonth: loadMonth,
        signals: signals,
        commands: ClassPresenceCommands(
          save: _Save(),
          validate: _Validate(),
          reopen: _Reopen(),
          retry: _Retry(),
        ),
        now: () => DateTime(2026, 10, 1, 9),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AcademicYearContextBloc>.value(value: years),
                BlocProvider<ClassroomOfflineBloc>.value(value: classes),
                BlocProvider<ClassPresenceCubit>.value(value: cubit),
              ],
              child: const ClassPresenceScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text("Choisissez la classe dont vous faites l'appel"),
        findsOneWidget,
      );

      await tester.tap(find.text('Choisir la classe').last);
      await tester.pumpAndSettle();
      expect(find.text('6ÈME PRIMAIRE'), findsOneWidget);
      await tester.tap(find.text('6e A'));
      await tester.pumpAndSettle();

      expect(find.text('Registre du jour'), findsOneWidget);
      verify(() => load(any())).called(greaterThan(0));

      await tester.tap(find.text('Récapitulatif du mois'));
      await tester.pumpAndSettle();
      verify(() => loadMonth(any())).called(greaterThan(0));
      expect(find.text('2. Jean Ilunga'), findsOneWidget);

      await tester.tap(find.text('2. Jean Ilunga'));
      await tester.pumpAndSettle();
      expect(find.text('FICHE MENSUELLE DE PRÉSENCE'), findsOneWidget);
      expect(find.text('Jean Ilunga'), findsWidgets);
    },
  );
}

class _Save extends Mock implements SaveClassPresenceMarksUseCase {}

class _Validate extends Mock implements ValidateClassPresenceDayUseCase {}

class _Reopen extends Mock implements ReopenClassPresenceDayUseCase {}

class _Retry extends Mock implements RetryClassPresenceDayUseCase {}
