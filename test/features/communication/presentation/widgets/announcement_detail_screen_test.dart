import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/detail/announcement_detail_screen.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../communication_fixtures.dart';

void main() {
  final sent = announcement(
    title: 'Fermeture exceptionnelle',
    body: 'Chers parents de {eleve}, école fermée vendredi.',
    status: AnnouncementStatus.sent,
    sentAt: DateTime.utc(2026, 10, 8, 17, 20),
    reachAtSend: reach,
  );

  Future<void> pump(WidgetTester tester, {VoidCallback? onDuplicate}) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: AnnouncementDetailScreen(
            announcement: sent,
            onBack: () {},
            onDuplicate: onDuplicate,
            now: () => DateTime.utc(2026, 10, 12, 9),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la portée figée, le message brut et l\'aperçu', (tester) async {
    await pump(tester);
    expect(find.text('113 messages sur 120'), findsOneWidget);
    expect(find.text("Toute l'école · 104 élèves"), findsOneWidget);
    expect(
      find.text('Chers parents de {eleve}, école fermée vendredi.'),
      findsOneWidget,
    );
    expect(find.text('Lire le communiqué'), findsOneWidget);
    expect(find.text('Dupliquer'), findsNothing);
  });

  testWidgets('dupliquer, avec le droit d\'envoyer', (tester) async {
    var duplicated = 0;
    await pump(tester, onDuplicate: () => duplicated++);
    await tester.tap(find.text('Dupliquer'));
    expect(duplicated, 1);
  });
}
