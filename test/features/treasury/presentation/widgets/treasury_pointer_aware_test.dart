import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/device/pointer_kind_scope.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_date_picker.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_button.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';

import '../../treasury_fixtures.dart';

/// Le bouton « Actualiser » et le sélecteur de date suivent la main réelle
/// (souris ou doigt), pas la plateforme.
Future<void> _hover(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(5, 5));
  await mouse.moveTo(const Offset(8, 8));
  addTearDown(mouse.removePointer);
  await tester.pump();
}

void main() {
  group('Actualiser', () {
    late int reads;

    Future<void> pump(WidgetTester tester) async {
      reads = 0;
      await tester.pumpWidget(
        treasuryHost(
          PointerKindScope(
            child: TreasuryRefreshScope(
              onRefresh: () async => reads++,
              // La portée couvre l'écran dans l'app : ici, une surface où
              // la souris passe.
              child: SizedBox(
                height: 200,
                child: Builder(
                  builder: (context) => Row(
                    children: TreasuryRefreshButton.headerActions(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('au doigt : pas de bouton (la page se tire)', (tester) async {
      await pump(tester);
      expect(find.text('Actualiser'), findsNothing);
    });

    testWidgets('écran tactile de bureau : le bouton reste au doigt, rien ne '
        'se tire', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pump(tester);
      await tester.tapAt(const Offset(5, 150));
      await tester.pump();
      expect(find.text('Actualiser'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('hors d une portée de relecture : pas de bouton', (
      tester,
    ) async {
      await tester.pumpWidget(
        treasuryHost(
          PointerKindScope(
            child: SizedBox(
              height: 200,
              child: Builder(
                builder: (context) =>
                    Row(children: TreasuryRefreshButton.headerActions(context)),
              ),
            ),
          ),
        ),
      );
      await _hover(tester);
      expect(find.text('Actualiser'), findsNothing);
    });

    testWidgets('à la souris : le bouton relit l écran', (tester) async {
      await pump(tester);
      await _hover(tester);
      expect(find.text('Actualiser'), findsOneWidget);
      await tester.tap(find.text('Actualiser'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(reads, 1);
    });
  });

  group('sélecteur de date', () {
    Future<void> open(WidgetTester tester, {required bool mouse}) async {
      await tester.pumpWidget(
        treasuryHost(
          PointerKindScope(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTreasuryDatePicker(
                  context,
                  initialDate: DateTime(2026, 10, 22),
                  firstDate: DateTime(2026, 9, 1),
                  lastDate: DateTime(2026, 10, 22),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      if (mouse) await _hover(tester);
      await tester.tap(
        find.text('ouvrir'),
        kind: mouse ? PointerDeviceKind.mouse : PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('au doigt : le calendrier', (tester) async {
      await open(tester, mouse: false);
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.byType(InputDatePickerFormField), findsNothing);
    });

    testWidgets('à la souris : la saisie', (tester) async {
      await open(tester, mouse: true);
      expect(find.byType(InputDatePickerFormField), findsOneWidget);
    });
  });
}
