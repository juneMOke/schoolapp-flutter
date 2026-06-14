import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockDisciplinaryCaseBloc
    extends MockBloc<DisciplinaryCaseEvent, DisciplinaryCaseState>
    implements DisciplinaryCaseBloc {}

void main() {
  late MockDisciplinaryCaseBloc bloc;

  setUp(() {
    bloc = MockDisciplinaryCaseBloc();
    whenListen(
      bloc,
      const Stream<DisciplinaryCaseState>.empty(),
      initialState: const DisciplinaryCaseState(),
    );
  });

  Widget harness(
    DisciplinaryCaseBloc bloc, {
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: viewInsets, disableAnimations: true),
          child: BlocProvider<DisciplinaryCaseBloc>.value(
            value: bloc,
            child: const DisciplinaryCaseCreateDialog(
              studentId: 's1',
              studentFirstName: 'Awa',
              studentLastName: 'Diop',
              studentGender: 'FEMALE',
              academicYearId: 'ay1',
            ),
          ),
        ),
      ),
    );
  }

  void setPhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(380, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('rendu sans exception sur téléphone étroit (380 dp)', (
    tester,
  ) async {
    setPhoneSurface(tester);

    await tester.pumpWidget(harness(bloc));
    await tester.pumpAndSettle();

    // Aucune exception de layout (débordement du segmenté Gravité, RenderBox
    // sans taille, etc.) au rendu sur petite largeur.
    expect(tester.takeException(), isNull);
    expect(find.byType(DisciplinaryCaseCreateDialog), findsOneWidget);
  });

  testWidgets('rendu sans exception avec clavier ouvert (inset bas)', (
    tester,
  ) async {
    setPhoneSurface(tester);

    // Inset clavier : l'ancienne double-compensation (AnimatedPadding +
    // maxHeight - inset) effondrait la zone de contenu -> débordement / crash.
    await tester.pumpWidget(
      harness(bloc, viewInsets: const EdgeInsets.only(bottom: 340)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DisciplinaryCaseCreateDialog), findsOneWidget);
  });
}
