import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/register/class_presence_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_commands.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_presence_notices.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_register_tab.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'class_presence_fixtures.dart';

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _Load extends Mock implements LoadClassPresenceDayUseCase {}

class _LoadMonth extends Mock implements LoadClassPresenceMonthUseCase {}

class _Save extends Mock implements SaveClassPresenceMarksUseCase {}

class _Validate extends Mock implements ValidateClassPresenceDayUseCase {}

class _Reopen extends Mock implements ReopenClassPresenceDayUseCase {}

class _Retry extends Mock implements RetryClassPresenceDayUseCase {}

class _Signals extends Mock implements ResourceSyncSignals {}

/// L'écran réel du registre : ce qu'il offre selon l'appel et les droits, et
/// ce que ses gestes envoient. Le **câblage** des gardes, pas seulement leurs
/// règles (une garde écrite et testée peut n'être jamais branchée).
void main() {
  const teacher = ['attendance.read', 'attendance.write'];
  const prefect = ['attendance.read', 'attendance.write', 'attendance.amend'];

  late _Save save;
  late _Validate validate;
  late _Reopen reopen;

  setUpAll(() {
    registerFallbackValue(const (classroomId: '', academicYearId: '', day: ''));
    registerFallbackValue(<String, PresenceMark<AbsenceReason>>{});
    registerFallbackValue(<ClassPresenceLine>[]);
  });

  Future<void> pump(
    WidgetTester tester, {
    required ClassPresenceDay day,
    List<String> permissions = teacher,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = _Auth();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(auth, Stream.value(authState), initialState: authState);

    final load = _Load();
    when(() => load(any())).thenAnswer((_) async => Right(day));
    save = _Save();
    validate = _Validate();
    reopen = _Reopen();
    when(() => save(any(), any())).thenAnswer((_) async => const Right(unit));
    when(
      () => validate(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
    when(() => reopen(any(), any())).thenAnswer((_) async => const Right(unit));
    final signals = _Signals();
    when(() => signals.watch(any())).thenReturn(() {});
    when(signals.pull).thenAnswer((_) async {});

    final cubit = ClassPresenceCubit(
      load: load,
      loadMonth: _LoadMonth(),
      signals: signals,
      commands: ClassPresenceCommands(
        save: save,
        validate: validate,
        reopen: reopen,
        retry: _Retry(),
        now: () => DateTime(2026, 10, 1, 7, 20),
      ),
      now: () => DateTime(2026, 10, 1, 7, 20),
    );
    addTearDown(cubit.close);
    cubit.setAcademicYear('y1', const SchoolYearBounds(start: '2026-09-01'));
    await cubit.selectClassroom(kClassroom);

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
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider<ClassPresenceCubit>.value(value: cubit),
            ],
            child: BlocConsumer<ClassPresenceCubit, ClassPresenceState>(
              listenWhen: (p, c) => c.notice != null && p.notice != c.notice,
              listener: (context, s) =>
                  showClassPresenceNotice(context, s.notice!),
              builder: (context, s) => SingleChildScrollView(
                child: ClassRegisterTab(
                  state: s,
                  register: s.register!,
                  classroomName: kClassroom.name,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('une touche sur une carte pointe l élève au brouillon', (
    tester,
  ) async {
    await pump(tester, day: presenceDay());

    await tester.tap(find.text('Zola'));
    await tester.pumpAndSettle();

    final marks =
        verify(() => save(any(), captureAny())).captured.single
            as Map<String, PresenceMark<AbsenceReason>>;
    expect(marks.keys, ['s3']);
  });

  testWidgets('valider : les non pointés partent présents, la modale le dit', (
    tester,
  ) async {
    await pump(tester, day: presenceDay());

    await tester.tap(find.text("Valider l'appel"));
    await tester.pumpAndSettle();
    expect(
      find.text("1 élève non pointé sera marqué présent à l'heure de début"),
      findsOneWidget,
    );
    // Pas de case : ils ne peuvent pas rester « à pointer ».
    expect(find.byType(CheckboxListTile), findsNothing);

    await tester.tap(find.text("Valider l'appel").last);
    await tester.pumpAndSettle();

    final lines =
        verify(() => validate(any(), captureAny())).captured.single
            as List<ClassPresenceLine>;
    expect(lines.every((l) => l.status.isMarked), isTrue);
  });

  testWidgets(
    'jour passé validé, sans attendance.amend : pas de Rouvrir, touche refusée',
    (tester) async {
      await pump(tester, day: presenceDay(day: '2026-09-30', validated: true));

      expect(find.text('Rouvrir'), findsNothing);
      expect(
        find.text(
          "Seuls le préfet et le directeur de discipline rouvrent l'appel "
          "d'un jour passé.",
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Mbuyi'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Appel validé — seuls le préfet et le directeur de discipline '
          'peuvent le rouvrir',
        ),
        findsOneWidget,
      );
      verifyNever(() => save(any(), any()));
    },
  );

  testWidgets('jour passé validé, avec attendance.amend : Rouvrir rouvre', (
    tester,
  ) async {
    await pump(
      tester,
      day: presenceDay(day: '2026-09-30', validated: true),
      permissions: prefect,
    );

    await tester.tap(find.text('Rouvrir'));
    await tester.pumpAndSettle();

    verify(() => reopen(any(), any())).called(1);
  });

  testWidgets('appel validé : « Justifier » reste ouvert (décision 9)', (
    tester,
  ) async {
    await pump(tester, day: presenceDay(day: '2026-09-30', validated: true));

    await tester.tap(find.text('Justifier').first);
    await tester.pumpAndSettle();
    expect(find.text('Justifier — Jean Ilunga'), findsOneWidget);

    await tester.tap(find.text('Maladie'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    verify(() => validate(any(), any())).called(1);
    verifyNever(() => reopen(any(), any()));
  });
}
