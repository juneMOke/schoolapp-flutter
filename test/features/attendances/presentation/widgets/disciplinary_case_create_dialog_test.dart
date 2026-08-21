import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// Écriture offline-first : le dialog dispatche/observe désormais le BLoC
// offline (création locale + outbox), c'est donc lui qu'on fournit ici.
class MockDisciplinaryCaseOfflineBloc
    extends MockBloc<DisciplinaryCaseOfflineEvent, DisciplinaryCaseOfflineState>
    implements DisciplinaryCaseOfflineBloc {}

void main() {
  late MockDisciplinaryCaseOfflineBloc bloc;

  setUp(() {
    bloc = MockDisciplinaryCaseOfflineBloc();
    whenListen(
      bloc,
      const Stream<DisciplinaryCaseOfflineState>.empty(),
      initialState: const DisciplinaryOfflineInitial(),
    );
  });

  Widget harness(
    DisciplinaryCaseOfflineBloc bloc, {
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
          child: BlocProvider<DisciplinaryCaseOfflineBloc>.value(
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

  // Le portrait ci-dessus laissait encore ~370 dp au dialog, de quoi tenir.
  // C'est le PAYSAGE qui ne pardonne pas : clavier ouvert, il ne reste qu'une
  // vingtaine de dp, quand l'en-tête et le pied à boutons en réclament plus de
  // deux cents. Le dialog débordait alors de 149 dp (640×360), 129 (760×380)
  // et 98 (731×411) — mesures prises avant que ces zones ne rejoignent le
  // défilement sous le seuil.
  for (final surface in const [
    Size(640, 360),
    Size(731, 411),
    Size(760, 380),
  ]) {
    testWidgets('paysage $surface, clavier ouvert : rien ne déborde', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        harness(bloc, viewInsets: const EdgeInsets.only(bottom: 300)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DisciplinaryCaseCreateDialog), findsOneWidget);
    });
  }
}
