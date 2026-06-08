import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_reassign_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockClassroomBloc extends MockBloc<ClassroomEvent, ClassroomState>
    implements ClassroomBloc {}

void main() {
  late MockClassroomBloc bloc;

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
    bloc = MockClassroomBloc();
    when(() => bloc.state).thenReturn(const ClassroomState());
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
        home: BlocProvider<ClassroomBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showClassesOrganisationReassignDialog(
                    context: context,
                    intent: intent,
                    options: options,
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

    verify(
      () => bloc.add(
        const ClassroomMemberReassignRequested(
          classroomMemberId: 'm1',
          targetClassroomId: 'c2',
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
          const ClassroomMemberReassignRequested(
            classroomMemberId: 'm9',
            targetClassroomId: 'c2',
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
