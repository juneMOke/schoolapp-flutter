import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_fiche_agent_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_year_list.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../hr_presence_builders.dart';

class _MockMonth extends Mock implements GetHrAttendanceAgentMonthUseCase {}

class _MockYear extends Mock implements GetHrAttendanceAgentYearUseCase {}

class _MockSource extends Mock implements StaffSnapshotSource {}

void main() {
  Future<({_MockMonth month, _MockYear year})> pump(
    WidgetTester tester, {
    bool yearly = false,
    Size? size = const Size(1280, 1400),
  }) async {
    if (size != null) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
    }
    final month = _MockMonth();
    final year = _MockYear();
    final source = _MockSource();
    when(
      () => source.read(),
    ).thenAnswer((_) async => const Left(StorageFailure('—')));
    when(
      () => month(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => Right(agentMonthOf()));
    when(() => year(any())).thenAnswer((_) async => Right(agentYearOf()));
    final cubit = HrPresenceFicheCubit(
      getMonth: month,
      getYear: year,
      source: source,
      args: (
        agentId: 'a-1',
        yearly: yearly,
        month: '2026-10',
        yearStart: DateTime(2026, 9, 1),
      ),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..load(),
          child: const HrPresenceFicheAgentScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (month: month, year: year);
  }

  testWidgets('vue mensuelle : le profil du mois, ses taux, son calendrier', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Profil · octobre 2026'), findsOneWidget);
    expect(find.text('Absentéiste'), findsOneWidget);
    expect(find.text('Taux de retard'), findsOneWidget);
    expect(find.text('2 jours sur 3 pointés'), findsOneWidget);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
    // La tendance appartient au détail du tableau de bord, pas à la fiche.
    expect(find.text('Tendance sur six mois'), findsNothing);
  });

  testWidgets('vue annuelle : un mois de classe ouvre sa vue mensuelle ; un '
      'mois à venir ne s\'ouvre pas', (tester) async {
    final mocks = await pump(tester, yearly: true);

    expect(find.byType(HrPresenceYearList), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    await tester.tap(find.text('novembre 2026'));
    await tester.pump();
    expect(find.byType(HrPresenceYearList), findsOneWidget);

    await tester.tap(find.text('septembre 2026'));
    await tester.pump();
    await tester.pump();
    verify(() => mocks.month('a-1', month: '2026-09')).called(1);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
  });

  testWidgets('la bascule Annuelle relit l\'année', (tester) async {
    final mocks = await pump(tester);
    await tester.tap(find.text('Annuelle'));
    await tester.pump();
    await tester.pump();
    verify(() => mocks.year('a-1')).called(1);
  });

  testAtReferenceFormats('la fiche mensuelle tient', (tester, format) async {
    await pump(tester, size: null);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
  });

  testAtReferenceFormats('la fiche annuelle tient', (tester, format) async {
    await pump(tester, size: null, yearly: true);
    expect(find.byType(HrPresenceYearList), findsOneWidget);
  });
}
