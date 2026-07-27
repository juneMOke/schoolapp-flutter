import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_reassign_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// La réassignation passe désormais par le BLoC offline (PUT online + re-pull
// best-effort) ; l'année scolaire courante est lue sur l'AcademicYearContextBloc.
class MockClassroomOfflineBloc
    extends MockBloc<ClassroomOfflineEvent, ClassroomOfflineState>
    implements ClassroomOfflineBloc {}

class MockAcademicYearContextBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

void main() {
  late MockClassroomOfflineBloc bloc;
  late MockAcademicYearContextBloc academicYearContextBloc;

  const options = [
    ClassroomReassignOption(
      id: 'c1',
      name: 'A',
      totalCount: 20,
      capacity: 40,
      femaleCount: 10,
      maleCount: 10,
    ),
    ClassroomReassignOption(
      id: 'c2',
      name: 'B',
      totalCount: 18,
      capacity: 40,
      femaleCount: 9,
      maleCount: 9,
    ),
    ClassroomReassignOption(
      id: 'c3',
      name: 'C',
      totalCount: 40,
      capacity: 40,
      femaleCount: 20,
      maleCount: 20,
    ),
  ];

  const transferIntent = ClassroomMemberReassignIntent(
    classroomId: 'c1',
    classroomMemberId: 'm1',
    studentId: 's1',
    studentFirstName: 'Jane',
    studentLastName: 'Doe',
    studentGender: ClassroomMemberGender.female,
    studentDisplayName: 'Doe Jane',
  );

  const assignIntent = ClassroomMemberReassignIntent(
    classroomId: null,
    classroomMemberId: 'm9',
    studentId: 's9',
    studentFirstName: 'Paul',
    studentLastName: 'Martin',
    studentGender: ClassroomMemberGender.male,
    studentDisplayName: 'Martin Paul',
  );

  setUp(() {
    bloc = MockClassroomOfflineBloc();
    when(() => bloc.state).thenReturn(const ClassroomOfflineState());
    academicYearContextBloc = MockAcademicYearContextBloc();
    when(
      () => academicYearContextBloc.state,
    ).thenReturn(const AcademicYearContextState.initial());
  });

  Future<void> openDialog(
    WidgetTester tester,
    ClassroomMemberReassignIntent intent,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ClassroomOfflineBloc>.value(value: bloc),
            BlocProvider<AcademicYearContextBloc>.value(
              value: academicYearContextBloc,
            ),
          ],
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showClassesOrganisationReassignDialog(
                    context: context,
                    intent: intent,
                    options: options,
                    schoolLevelId: 'level-1',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('transfert : eyebrow, rappel, actuelle/complet, stats', (
    tester,
  ) async {
    await openDialog(tester, transferIntent);

    expect(find.text('TRANSFÉRER L\'ÉLÈVE'), findsOneWidget);
    expect(find.text('Doe Jane'), findsOneWidget);
    expect(find.text('Classe actuelle'), findsOneWidget);
    expect(find.text('Actuelle'), findsOneWidget); // classe d'origine (c1)
    expect(find.text('Complet'), findsOneWidget); // c3 pleine
    expect(find.text('18/40 · G 9 · F 9'), findsOneWidget); // stats c2
  });

  testWidgets('transfert : choix d\'une cible puis validation dispatche', (
    tester,
  ) async {
    await openDialog(tester, transferIntent);

    // Bouton inactif tant qu'aucune cible n'est choisie.
    final actionFinder = find.widgetWithText(FilledButton, 'Transférer');
    expect(tester.widget<FilledButton>(actionFinder).onPressed, isNull);

    await tester.tap(find.text('Classe B'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(actionFinder).onPressed, isNotNull);

    await tester.tap(actionFinder);
    await tester.pumpAndSettle();

    // Origine non nulle (c1) → TRANSFERT offline (événement), pas l'affectation.
    verify(
      () => bloc.add(
        const MemberTransferRequested(
          studentId: 's1',
          fromClassroomId: 'c1',
          toClassroomId: 'c2',
          schoolLevelId: 'level-1',
          academicYearId: '',
        ),
      ),
    ).called(1);
  });

  testWidgets(
    'affectation : eyebrow « Affecter l\'élève » + état non réparti',
    (tester) async {
      await openDialog(tester, assignIntent);

      expect(find.text('AFFECTER L\'ÉLÈVE'), findsOneWidget);
      expect(find.text('Non réparti'), findsOneWidget);
      expect(find.text('Actuelle'), findsNothing); // pas de classe d'origine

      await tester.tap(find.text('Classe B'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Affecter'));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(
          const MemberReassignRequested(
            classroomMemberId: 'm9',
            targetClassroomId: 'c2',
            academicYearId: '',
          ),
        ),
      ).called(1);
    },
  );

  testWidgets('popin sans débordement sur écran étroit (320px)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openDialog(tester, transferIntent);

    expect(tester.takeException(), isNull);
  });
}
