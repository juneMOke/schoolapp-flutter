import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_rate_bars.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_month_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_agent_page.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../hr_presence_builders.dart';

class _MockGet extends Mock implements GetHrAttendanceAgentMonthUseCase {}

class _MockSource extends Mock implements StaffSnapshotSource {}

class _MockAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

StaffFileSnapshot _file() => StaffFileSnapshot(
  members: [
    member('a-1', lastName: 'KABASELE-TSHIMANGA', firstName: 'Marie-Béatrice'),
    member('a-2', lastName: 'Mayala', firstName: 'Ruth'),
  ],
  documentsByMember: const {},
  documentTypes: const [],
  hasEverSynced: true,
);

void main() {
  Future<_MockGet> pump(
    WidgetTester tester, {
    Either<Failure, Object>? answer,
    List<String>? permissions,
    Size? size = const Size(1280, 1400),
    StaffPayMode? payMode,
  }) async {
    if (size != null) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
    }
    final get = _MockGet();
    final source = _MockSource();
    // Le fichier local nourrit le sélecteur : posé, il entre dans la mise en
    // page aux formats.
    when(() => source.read()).thenAnswer((_) async => Right(_file()));
    when(() => get(any(), month: any(named: 'month'))).thenAnswer(
      (_) async => answer == null
          ? Right(agentMonthOf(payMode: payMode))
          : answer.fold(Left.new, (_) => Right(agentMonthOf())),
    );
    final cubit = HrPresenceAgentMonthCubit(
      getMonth: get,
      source: source,
      agentId: 'a-1',
      month: '2026-10',
      yearStart: DateTime(2026, 9, 1),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    Widget screen = BlocProvider.value(
      value: cubit..load(),
      child: const HrPresenceAgentScreen(),
    );
    if (permissions != null) {
      final auth = _MockAuth();
      final state = AuthState(
        status: AuthStatus.authenticated,
        permissions: permissions,
      );
      when(() => auth.state).thenReturn(state);
      whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
      screen = BlocProvider<AuthBloc>.value(value: auth, child: screen);
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    );
    await tester.pump();
    await tester.pump();
    return get;
  }

  testWidgets('le mois de l\'agent : identité, tuiles, calendrier, tendance '
      'et incidents', (tester) async {
    await pump(tester);

    expect(find.text('Présence de l\'agent'), findsOneWidget);
    expect(find.text('MWAMBA ILUNGA Clarisse'), findsOneWidget);
    expect(find.text('Secrétaire · Permanent · CF-AG-0012'), findsOneWidget);
    expect(find.text('67 %'), findsWidgets);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('17 jours de classe · 14 non pointés'), findsOneWidget);
    expect(find.text('Non pointés'), findsOneWidget);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
    expect(find.text('Tendance sur six mois'), findsOneWidget);
    expect(find.byType(PresenceRateBars), findsOneWidget);
    expect(find.text('Retards et absences du mois'), findsOneWidget);
  });

  testWidgets('un vacataire à l\'heure : ses heures, pas les non-pointés', (
    tester,
  ) async {
    await pump(tester, payMode: StaffPayMode.hourly);

    expect(find.text('Heures prestées'), findsOneWidget);
    expect(find.text('Non pointés'), findsNothing);
  });

  testWidgets('« Voir sa paie » : à qui lit la paie seulement', (tester) async {
    await pump(tester, permissions: [Perm.hrAttendanceRead.wire]);
    expect(find.text('Voir sa paie'), findsNothing);
  });

  testWidgets('le mois précédent relit le serveur', (tester) async {
    final get = await pump(tester);
    await tester.tap(find.byTooltip('Mois précédent'));
    await tester.pump();
    await tester.pump();

    verify(() => get('a-1', month: '2026-09')).called(1);
  });

  testWidgets('un agent inconnu du serveur : introuvable, sans « Réessayer »', (
    tester,
  ) async {
    await pump(tester, answer: const Left(NotFoundFailure('agent')));

    expect(find.text('Agent introuvable'), findsOneWidget);
    expect(find.byType(EteeloErrorResult), findsNothing);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('hors ligne : l\'erreur réseau', (tester) async {
    await pump(tester, answer: const Left(NetworkFailure('—')));
    expect(find.byType(EteeloErrorResult), findsOneWidget);
  });

  testAtReferenceFormats('le détail d\'un agent tient', (tester, format) async {
    await pump(tester, size: null);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
  });
}
