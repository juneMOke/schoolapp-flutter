import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_buttons.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('un double appui n’ouvre qu’une visionneuse (I19)', (
    tester,
  ) async {
    final opened = <RecoveryExportFormat>[];
    final viewer = Completer<void>();
    await _pump(
      tester,
      RecoveryFormatButtons(
        onSelected: (format) {
          opened.add(format);
          return viewer.future;
        },
      ),
    );
    await tester.tap(find.text('PDF'));
    await tester.tap(find.text('PDF'));
    await tester.tap(find.text('Excel'));
    await tester.pump();
    expect(opened, [RecoveryExportFormat.pdf]);
    viewer.complete();
    await tester.pump();
    await tester.tap(find.text('Excel'));
    expect(opened, [RecoveryExportFormat.pdf, RecoveryExportFormat.xlsx]);
  });

  testWidgets('inactifs : la raison en info-bulle, cible 48 dp', (
    tester,
  ) async {
    await _pump(
      tester,
      RecoveryFormatButtons(
        enabled: false,
        disabledReason: 'Les exports attendent le réseau.',
        onSelected: (_) async {},
      ),
    );
    expect(
      find.byTooltip('Les exports attendent le réseau.'),
      findsNWidgets(2),
    );
    final pdf = find.widgetWithText(OutlinedButton, 'PDF');
    expect(tester.widget<OutlinedButton>(pdf).onPressed, isNull);
    expect(tester.getSize(pdf).height, greaterThanOrEqualTo(48));
  });
}
