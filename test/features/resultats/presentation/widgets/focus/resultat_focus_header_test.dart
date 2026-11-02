import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/focus/resultat_focus_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../../test_helpers/reference_formats.dart';

/// L'en-tête de la fiche d'un élève (Résultats, vue focus) : le retour à la
/// classe est une vraie cible — 48 dp au doigt, nommée par une info-bulle.
/// L'ancien carreau faisait 38 × 38 sans nom.
void main() {
  Future<void> pump(WidgetTester tester, {required VoidCallback onBack}) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResultatFocusHeader(
                prenom: 'Ruth',
                nom: 'Mayala',
                postnom: 'Nsimba',
                genre: ClassroomMemberGender.female,
                classroomLabel: '6e A',
                studentId: 's-1',
                moyenneAnnuelle: 72.5,
                rang: 3,
                nbClasses: 41,
                onBack: onBack,
              ),
            ),
          ),
        ),
      );

  const back = 'Retour à la vue classe';

  testAtReferenceFormats('le retour fait 48 dp et se nomme', (
    tester,
    format,
  ) async {
    var backs = 0;
    await pump(tester, onBack: () => backs++);

    final button = find.ancestor(
      of: find.byTooltip(back),
      matching: find.byType(IconButton),
    );
    final size = tester.getSize(button);
    expect(size.width, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));

    await tester.tap(button);
    expect(backs, 1);
  });

  testWidgets(
    'à la souris aussi, la cible garde 48 dp',
    (tester) async {
      await pump(tester, onBack: () {});
      final button = find.ancestor(
        of: find.byTooltip(back),
        matching: find.byType(IconButton),
      );
      expect(tester.getSize(button).width, AppDimensions.minTouchTarget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
