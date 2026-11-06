import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_kind_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le statut choisi se voit sans la couleur : une coche sur sa seule tuile.
void main() {
  Future<void> pump(WidgetTester tester, StaffContractKind? selected) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StaffContractKindPicker(
              selected: selected,
              onChanged: (_) {},
            ),
          ),
        ),
      );

  testWidgets('la tuile choisie porte une coche, et elle seule', (
    tester,
  ) async {
    await pump(tester, StaffContractKind.permanent);
    final check = find.byIcon(Icons.check_circle_rounded);
    expect(check, findsOneWidget);
    // La coche est dans la tuile « Permanent ».
    final tile = find.ancestor(
      of: find.text('Permanent'),
      matching: find.byType(InkWell),
    );
    expect(find.descendant(of: tile, matching: check), findsOneWidget);
  });

  testWidgets('rien de choisi : aucune coche', (tester) async {
    await pump(tester, null);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });
}
