import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpIndicator(
    WidgetTester tester, {
    required SyncStatus status,
    int? lastSyncAtMs,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SyncIndicator(status: status, lastSyncAtMs: lastSyncAtMs),
        ),
      ),
    );
  }

  int msAgo(Duration d) => DateTime.now().subtract(d).millisecondsSinceEpoch;

  testWidgets('sans lastSyncAtMs : aucun texte relatif', (tester) async {
    await pumpIndicator(tester, status: SyncStatus.synced);
    expect(find.textContaining('·'), findsNothing);
    expect(find.text('À jour'), findsOneWidget);
  });

  testWidgets('moins d\'une minute → « À l\'instant »', (tester) async {
    await pumpIndicator(
      tester,
      status: SyncStatus.synced,
      lastSyncAtMs: msAgo(const Duration(seconds: 10)),
    );
    expect(find.textContaining('À l\'instant'), findsOneWidget);
  });

  testWidgets('quelques minutes → « il y a N min »', (tester) async {
    await pumpIndicator(
      tester,
      status: SyncStatus.offline,
      lastSyncAtMs: msAgo(const Duration(minutes: 12)),
    );
    expect(find.textContaining('Il y a 12 min'), findsOneWidget);
  });

  testWidgets('quelques heures → « il y a N h »', (tester) async {
    await pumpIndicator(
      tester,
      status: SyncStatus.offline,
      lastSyncAtMs: msAgo(const Duration(hours: 3)),
    );
    expect(find.textContaining('Il y a 3 h'), findsOneWidget);
  });

  testWidgets('plusieurs jours → « il y a N jours »', (tester) async {
    await pumpIndicator(
      tester,
      status: SyncStatus.offline,
      lastSyncAtMs: msAgo(const Duration(days: 2)),
    );
    expect(find.textContaining('Il y a 2 jours'), findsOneWidget);
  });

  testWidgets('le texte relatif suit le libellé de statut (séparateur)', (
    tester,
  ) async {
    await pumpIndicator(
      tester,
      status: SyncStatus.offline,
      lastSyncAtMs: msAgo(const Duration(minutes: 5)),
    );
    expect(find.text('Hors ligne · Il y a 5 min'), findsOneWidget);
  });

  group('partiellement à jour (ADR-015 F1)', () {
    testWidgets('libellé FR dédié, distinct de « À jour »', (tester) async {
      await pumpIndicator(tester, status: SyncStatus.partiallySynced);

      expect(find.text('Partiellement à jour'), findsOneWidget);
      // Le point du lot : sans ce statut la pastille disait « À jour » alors
      // que des domaines entiers manquaient au cache local.
      expect(find.text('À jour'), findsNothing);
    });

    testWidgets('se concatène au relatif comme les autres statuts', (
      tester,
    ) async {
      await pumpIndicator(
        tester,
        status: SyncStatus.partiallySynced,
        lastSyncAtMs: msAgo(const Duration(minutes: 5)),
      );

      expect(find.text('Partiellement à jour · Il y a 5 min'), findsOneWidget);
    });

    testWidgets('icône et teinte neutres : un manque, pas une panne', (
      tester,
    ) async {
      await pumpIndicator(tester, status: SyncStatus.partiallySynced);

      // Teinte neutre assumée : un compte au périmètre étroit vit dans cet
      // état en permanence, l'ambre ou le rouge l'accuseraient d'une panne.
      final icon = tester.widget<Icon>(find.byIcon(Icons.cloud_done_outlined));
      expect(icon.color, AppColors.textMuted);
    });
  });
}
