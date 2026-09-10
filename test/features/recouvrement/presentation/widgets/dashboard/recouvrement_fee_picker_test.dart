import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_fee_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<Set<String>?> pump(
    WidgetTester tester, {
    required List<String> feeCodes,
    required Set<String> selected,
    bool enabled = true,
  }) async {
    Set<String>? emitted;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecouvrementFeePicker(
            feeCodes: feeCodes,
            selected: selected,
            enabled: enabled,
            onChanged: (next) => emitted = next,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return emitted;
  }

  group('la sélection', () {
    testWidgets('cocher une nature l\'ajoute sans retirer les autres', (
      tester,
    ) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RecouvrementFeePicker(
              feeCodes: const ['TUITION', 'BOOKS'],
              selected: const {'TUITION'},
              onChanged: (next) => emitted = next,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      expect(emitted, {'TUITION', 'BOOKS'});
    });

    testWidgets('décocher une nature parmi plusieurs la retire', (
      tester,
    ) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RecouvrementFeePicker(
              feeCodes: const ['TUITION', 'BOOKS'],
              selected: const {'TUITION', 'BOOKS'},
              onChanged: (next) => emitted = next,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_box).first);
      await tester.pumpAndSettle();

      expect(emitted, hasLength(1));
    });
  });

  group('la dernière pastille', () {
    testWidgets(
      'ne se décoche pas — le clic est IGNORÉ, sans erreur ni message',
      (tester) async {
        Set<String>? emitted;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RecouvrementFeePicker(
                feeCodes: const ['TUITION', 'BOOKS'],
                selected: const {'TUITION'},
                onChanged: (next) => emitted = next,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.check_box));
        await tester.pumpAndSettle();

        expect(
          emitted,
          isNull,
          reason: 'aucune sélection émise : le geste n\'aboutit pas',
        );
        expect(
          find.byType(SnackBar),
          findsNothing,
          reason: 'une garde ne se signale pas comme une panne',
        );
      },
    );

    testWidgets('s\'annonce verrouillée à l\'assistance vocale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        feeCodes: const ['TUITION', 'BOOKS'],
        selected: const {'TUITION'},
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(
        find.bySemanticsLabel(
          l10n.recouvrementFeeChipLockedA11y(l10n.studentChargeFeeCodeTuition),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('pendant une lecture', () {
    testWidgets('les pastilles sont inertes : un geste ne part pas deux fois', (
      tester,
    ) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RecouvrementFeePicker(
              feeCodes: const ['TUITION', 'BOOKS'],
              selected: const {'TUITION'},
              enabled: false,
              onChanged: (next) => emitted = next,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pumpAndSettle();

      expect(emitted, isNull);
    });
  });
}
