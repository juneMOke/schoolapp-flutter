import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/selection/cote_scope_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/ink_visibility.dart';
import '../bloc/fake_cotes_repository.dart';

/// Les puces de la portée : leur fond ne recouvre pas le survol ni le focus,
/// et la puce choisie, pleine d'accent, prend le voile des surfaces sombres.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CoteScopeBar(
            classe: demoClasse,
            scope: const CoteScope(portee: CotePortee.groupe, cibleId: 'S1'),
            year: const [],
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('le fond des puces ne couvre pas l\'encre', (tester) async {
    await pump(tester);
    final chips = find.ancestor(
      of: find.textContaining('Semestre'),
      matching: find.byType(InkWell),
    );
    expect(chips, findsNWidgets(2));
    expectInkNotCovered(tester, chips);
  });

  testWidgets('la puce choisie prend le voile des surfaces sombres', (
    tester,
  ) async {
    await pump(tester);
    InkWell chip(String label) => tester.widget<InkWell>(
      find.ancestor(
        of: find.textContaining(label),
        matching: find.byType(InkWell),
      ),
    );
    expect(chip('Semestre 1').focusColor, AppColors.stateFocusOnDark);
    expect(chip('Semestre 2').focusColor, isNull);
  });
}
