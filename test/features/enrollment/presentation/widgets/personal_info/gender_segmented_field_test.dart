import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/gender_segmented_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('en lecture (readOnly) : sélection conservée + non interactif', (
    tester,
  ) async {
    var changed = false;
    await tester.pumpWidget(
      harness(
        GenderSegmentedField(
          width: 400,
          label: 'Genre',
          selectedGender: Gender.female,
          onChanged: (_) => changed = true,
          readOnly: true,
        ),
      ),
    );

    // Bug corrigé : en lecture le bouton garde un handler non-null → Material le
    // rend "actif" et met le segment sélectionné en évidence (au lieu de griser).
    final segmented = tester.widget<SegmentedButton<Gender>>(
      find.byType(SegmentedButton<Gender>),
    );
    expect(segmented.onSelectionChanged, isNotNull);
    expect(segmented.selected, equals({Gender.female}));

    // ...mais non interactif : taper l'autre segment ne déclenche rien.
    await tester.tap(find.byIcon(Icons.male_rounded), warnIfMissed: false);
    await tester.pump();
    expect(changed, isFalse);
  });

  testWidgets('en édition : interactif (sélection modifiable)', (tester) async {
    Gender? received;
    await tester.pumpWidget(
      harness(
        GenderSegmentedField(
          width: 400,
          label: 'Genre',
          selectedGender: Gender.female,
          onChanged: (value) => received = value,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.male_rounded));
    await tester.pump();
    expect(received, Gender.male);
  });
}
