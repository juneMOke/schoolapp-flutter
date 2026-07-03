import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_timetable_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'se rend dans un scrollable vertical étroit sans forcer une hauteur infinie',
    (tester) async {
      // Reproduit le contexte réel (AppPageBackground scrollable) sur petit
      // écran : largeur téléphone + hauteur NON bornée. Sans IntrinsicHeight, le
      // Row `stretch` du corps jetait « BoxConstraints forces an infinite height ».
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: ScheduleTimetableSkeleton()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ScheduleTimetableSkeleton), findsOneWidget);
    },
  );
}
