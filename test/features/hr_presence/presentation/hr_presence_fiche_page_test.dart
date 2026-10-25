import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_fiche_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_profile_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../hr_presence_builders.dart';

class _MockGet extends Mock implements GetHrAttendanceProfilesUseCase {}

void main() {
  setUpAll(() => registerFallbackValue(const HrProfileScope.year()));

  Future<List<HrAttendanceProfileRow>> pump(
    WidgetTester tester, {
    HrAttendanceProfiles? answer,
    Failure? failure,
    Size? size = const Size(1280, 1400),
  }) async {
    if (size != null) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
    }
    final get = _MockGet();
    when(() => get(any())).thenAnswer(
      (_) async =>
          failure == null ? Right(answer ?? profilesOf()) : Left(failure),
    );
    final cubit = HrPresenceProfilesCubit(
      getProfiles: get,
      yearStart: DateTime(2026, 9, 1),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    final opened = <HrAttendanceProfileRow>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..load(),
          child: HrPresenceFicheScreen(
            onOpenAgent: (_, row) => opened.add(row),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return opened;
  }

  testWidgets('une ligne par agent, le profil écrit et coloré', (tester) async {
    await pump(tester);

    expect(find.byType(HrPresenceProfileRow), findsNWidgets(3));
    expect(find.text('MWAMBA Clarisse'), findsOneWidget);
    expect(find.text('Secrétaire · Administratif'), findsOneWidget);
    expect(find.text('79 % · 9 % · 21 %'), findsOneWidget);
    // Une puce et un badge par profil présent.
    expect(find.text('Absentéiste'), findsNWidgets(2));
  });

  testWidgets('une puce filtre ; un second appui rend la liste', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Exemplaire').first);
    await tester.pump();
    expect(find.byType(HrPresenceProfileRow), findsOneWidget);

    await tester.tap(find.text('Exemplaire').first);
    await tester.pump();
    expect(find.byType(HrPresenceProfileRow), findsNWidgets(3));
  });

  testWidgets('toucher une ligne ouvre sa fiche', (tester) async {
    final opened = await pump(tester);
    await tester.tap(find.text('MAYALA Ruth'));
    expect(opened.single.agent.staffMemberId, 'a-2');
  });

  testWidgets('l\'œil de l\'app, sur chaque ligne, ouvre aussi la fiche', (
    tester,
  ) async {
    final opened = await pump(tester);
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    expect(opened.single.agent.staffMemberId, 'a-1');
  });

  testWidgets('un mois de vacances le dit', (tester) async {
    await pump(tester, answer: profilesOf(classDays: 0, staff: const []));
    expect(find.byType(PresenceHolidayState), findsOneWidget);
  });

  testWidgets('une recherche sans résultat propose « Tout afficher »', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump();
    expect(find.text('Aucun agent ne correspond'), findsOneWidget);
    await tester.tap(find.text('Tout afficher'));
    await tester.pump();
    expect(find.byType(HrPresenceProfileRow), findsNWidgets(3));
  });

  testAtReferenceFormats('la liste par profil tient', (tester, format) async {
    await pump(
      tester,
      size: null,
      answer: profilesOf(
        staff: [
          profileRow(
            'a',
            lastName: 'KABASELE-TSHIMANGA',
            firstName: 'Marie-Béatrice',
            jobTitle: 'Professeure principale de mathématiques et de physique',
          ),
          profileRow(
            'b',
            lastName: 'MAYALA',
            firstName: 'Ruth',
            presence: null,
            late: null,
            absent: null,
          ),
        ],
      ),
    );
    expect(find.byType(HrPresenceProfileRow), findsNWidgets(2));
  });
}
