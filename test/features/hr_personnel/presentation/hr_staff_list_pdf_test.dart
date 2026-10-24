import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/export/hr_staff_list_export.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/export/hr_staff_list_pdf.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

import '../hr_personnel_builders.dart';

void main() {
  test(
    'compose un PDF, agents hors ligne compris, sur plusieurs pages',
    () async {
      final rows = viewOf([
        for (var i = 0; i < 80; i++) agent('a$i', lastName: 'Agent $i'),
        agent('p', staffNumber: null, syncState: RecordSyncState.pending),
      ]).all;

      final bytes = await HrStaffListPdf.build(
        rows: rows,
        query: HrRosterQuery.none,
        today: '2026-10-24',
        academicYear: '2026-2027',
        schoolName: 'Complexe scolaire Eteelo',
        issuedDate: '24/10/2026',
        issuedTime: '10h12',
        l10n: AppLocalizationsFr(),
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );

  test('le nom de fichier porte la catégorie et le jour', () {
    final day = DateTime(2026, 10, 4);
    expect(
      HrStaffListExport.fileName(HrRosterQuery.none, day),
      'personnel-20261004.pdf',
    );
    expect(
      HrStaffListExport.fileName(
        HrRosterQuery.none.withCategory(HrCategoryKey.teacher),
        day,
      ),
      'personnel-teacher-20261004.pdf',
    );
  });

  test('les apostrophes et tirets typographiques restent imprimables', () {
    expect(HrStaffListPdf.printable('N’Sele'), "N'Sele");
    expect(HrStaffListPdf.printable('2026–2027'), '2026-2027');
    expect(HrStaffListPdf.printable('Cœur'), 'Coeur');
    expect(HrStaffListPdf.printable('Élodie'), 'Élodie');
  });
}
