import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

class _Years
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _Enrollments
    extends MockBloc<EnrollmentLocalListEvent, EnrollmentLocalListState>
    implements EnrollmentLocalListBloc {}

/// Grand écran : la fiche d'un élève s'ouvre à côté de la liste. Tant
/// qu'aucun élève n'est choisi, le volet de droite y invite.
void main() {
  final l10n = AppLocalizationsFr();

  setUpAll(() => registerFallbackValue(const AcademicYearContextRequested()));

  Future<void> pump(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const yearState = AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: AcademicYearContext(
        academicYear: AcademicYear(id: 'y1', name: '2026-2027', current: true),
        schoolLevelGroups: [],
      ),
    );
    final years = _Years();
    whenListen(
      years,
      const Stream<AcademicYearContextState>.empty(),
      initialState: yearState,
    );
    final enrollments = _Enrollments();
    whenListen(
      enrollments,
      const Stream<EnrollmentLocalListState>.empty(),
      initialState: const EnrollmentLocalListState.initial(),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AcademicYearContextBloc>.value(value: years),
          BlocProvider<EnrollmentLocalListBloc>.value(value: enrollments),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FacturationPage()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('grand écran : le volet de la fiche attend un élève', (
    tester,
  ) async {
    await pump(tester, const Size(1600, 1000));
    expect(find.text(l10n.facturationPickStudentTitle), findsOneWidget);
    expect(find.text(l10n.facturationSearchInvitationTitle), findsOneWidget);
  });

  testWidgets('écran moyen : la liste seule, la fiche s’ouvrira en page', (
    tester,
  ) async {
    await pump(tester, const Size(1200, 900));
    expect(find.text(l10n.facturationPickStudentTitle), findsNothing);
    expect(find.text(l10n.facturationSearchInvitationTitle), findsOneWidget);
  });

  testWidgets('redimensionner ne perd pas les critères saisis', (tester) async {
    await pump(tester, const Size(1600, 1000));
    final field = find.byType(EditableText).first;
    await tester.enterText(field, 'Mbuyi');
    await tester.pump();

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();
    expect(find.text(l10n.facturationPickStudentTitle), findsNothing);
    expect(find.text('Mbuyi'), findsOneWidget);

    tester.view.physicalSize = const Size(1600, 1000);
    await tester.pump();
    expect(find.text('Mbuyi'), findsOneWidget);
  });
}
