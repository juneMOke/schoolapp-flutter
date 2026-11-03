import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_card.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_header_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

/// À 620, les notes ne tiennent pas : elles défilent de côté.
const _scrolls = Size(620, 900);

/// L'en-tête collant et ce qui le suit : la page qui défile, les notes qui
/// défilent de côté, et ce qui change sous eux.
void main() {
  late FakeCotesRepository repository;
  late CoteSaisieBloc bloc;

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    Widget? above,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = FakeCotesRepository();
    bloc = CoteSaisieBloc(repository);
    final save = CoteSaveCubit(repository);
    bloc.add(const CoteSaisieOpened('c1'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: save),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?above,
                  const CoteBulletinCard(classroomName: '7e A'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    addTearDown(() async {
      await tester.runAsync(() async {
        await save.close();
        await bloc.close();
      });
    });
  }

  Finder header(String text) => find.descendant(
    of: find.byType(CoteGridHeaderBand),
    matching: find.text(text),
  );

  ScrollPosition page(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .ancestor(
              of: find.byType(CoteGrid),
              matching: find.byType(Scrollable),
            )
            .last,
      )
      .position;

  ScrollController notes(WidgetTester tester) => tester
      .widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(CoteGrid),
          matching: find.byType(SingleChildScrollView),
        ),
      )
      .controller!;

  Future<void> scrollPageTo(WidgetTester tester, double offset) async {
    page(tester).jumpTo(offset);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('colle encore quand la page change d\'échelle', (tester) async {
    await pump(tester, size: const Size(1280, 300));
    final gridTop = tester.getTopLeft(find.byType(CoteGrid)).dy;

    // Zoom du navigateur, écran d'une autre échelle : la page refait sa
    // position de défilement.
    tester.view.physicalSize = const Size(2560, 600);
    tester.view.devicePixelRatio = 2;
    await tester.pump();
    await tester.pump();
    await scrollPageTo(tester, gridTop + 60);

    expect(tester.getTopLeft(header('COURS')).dy, inInclusiveRange(0, 12));
  });

  testWidgets('reste aligné sur les notes quand la grille s\'élargit', (
    tester,
  ) async {
    await pump(tester, size: _scrolls);
    final controller = notes(tester);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    // Plus large, la fin des notes revient plus tôt : le défileur ramène son
    // décalage, sans le dire.
    tester.view.physicalSize = const Size(700, 900);
    await tester.pump();
    await tester.pump();

    final cell = find.byType(TextField).first;
    expect(
      tester.getCenter(header('P1')).dx,
      closeTo(tester.getCenter(cell).dx, 1),
    );
  });
}
