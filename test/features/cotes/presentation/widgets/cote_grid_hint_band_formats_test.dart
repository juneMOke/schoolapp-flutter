import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_hint_band.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../bloc/fake_cotes_repository.dart';
import 'cote_grid_hint_band_harness.dart';

void main() {
  testAtReferenceFormats('une aide longue tient dans la bande', (
    tester,
    format,
  ) async {
    await pumpHintBulletin(
      tester,
      cells: [
        CoteCell(
          key: demoKey('S1', cours: 'an'),
          hasDraft: true,
          draftValue: 12,
          syncState: SyncState.syncError,
          rejectionReason: 'PERIODE_CLOSE',
        ),
      ],
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    // Anglais, examen : la dernière case, loin à droite sur téléphone.
    tester.widget<TextField>(gridField(5)).focusNode!.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      bandText(tester),
      'Anglais · Examen · Semestre 1 : Refusée : colonne clôturée '
      'entre-temps. Le serveur ne l\'a pas gardée.',
    );
    final band = tester.getRect(hintPanel);
    expect(band.left, greaterThanOrEqualTo(0));
    expect(band.right, lessThanOrEqualTo(format.size.width));
    expect(band.bottom, lessThanOrEqualTo(format.size.height));
    expect(band.height, greaterThan(0));
    // Repliée sans focus : elle ne prend aucune place dans la page.
    expect(tester.getSize(find.byType(CoteGridHintBand)).height, 0);
  });
}
