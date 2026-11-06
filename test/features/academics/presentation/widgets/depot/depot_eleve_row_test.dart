import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/depot/depot_eleve_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../../test_helpers/reference_formats.dart';

/// Une copie rendue en retard, consultable en ligne seulement : la pastille
/// la plus longue à côté du bouton le plus long.
void main() {
  final eleve = CopieRendue(
    studentId: 's1',
    firstName: 'Grâce',
    lastName: 'Mbuyi',
    middleName: 'Kalala',
    depot: DepotCopie(
      id: 'd1',
      studentId: 's1',
      depositedAt: DateTime.utc(2026, 9, 30, 9),
      enRetard: true,
      fichiers: const [
        DepotFichier(
          id: 'p1',
          ordre: 1,
          ref: AttachmentRef(
            name: 'p1.jpg',
            mimeType: 'image/jpeg',
            sizeBytes: 1,
            sha256: 'p1',
          ),
        ),
      ],
    ),
  );

  testAtReferenceFormats('rendu en retard, copie en ligne : la ligne tient', (
    tester,
    format,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            // Gouttière de page, puis marge de la carte et de la section.
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: DepotEleveRow(eleve: eleve, canOpen: false, onOpen: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rendu en retard'), findsOneWidget);
    expect(find.text('Copie disponible en ligne'), findsOneWidget);
  });
}
