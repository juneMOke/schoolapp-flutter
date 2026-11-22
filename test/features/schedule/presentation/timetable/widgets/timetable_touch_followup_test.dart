import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/consultation_actions.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/dated_week_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: c!,
  ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('téléphone : l’icône Imprimer s’annonce au lecteur d’écran', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        ConsultationActions(
          mode: ClassTimetableMode.week,
          onMode: (_) {},
          week: const SizedBox.shrink(),
          published: true,
          online: true,
          narrow: true,
          onPrint: () {},
          onEdit: null,
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(find.byTooltip("Imprimer l'emploi du temps"), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('×1,3 sur 360 dp : ‹ et › restent sur la ligne de la semaine', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(328, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        DatedWeekBar(
          monday: DateTime.utc(2026, 6, 8),
          isThisWeek: false,
          onPrevious: () {},
          onNext: () {},
          onThisWeek: () {},
        ),
        textScale: 1.3,
      ),
    );
    final previous = tester.getCenter(find.byIcon(Icons.chevron_left));
    final next = tester.getCenter(find.byIcon(Icons.chevron_right));
    expect((previous.dy - next.dy).abs(), lessThan(1));
  });
}
