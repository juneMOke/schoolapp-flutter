import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/reports_table.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

Map<String, Object?> _json({bool? archived, String? archivedAt}) => {
  'id': 'RJ-20261021',
  'kind': 'DAILY',
  'from': '2026-10-21',
  'to': '2026-10-21',
  'title': 'Mercredi 21 octobre 2026',
  'status': 'FINAL',
  'inProgress': false,
  'currencies': ['USD'],
  'archived': ?archived,
  'archivedAt': ?archivedAt,
};

void main() {
  test('archived se lit ; absent, le rapport n est pas archivé', () {
    final archived = TreasuryWire.reportFromJson(
      _json(archived: true, archivedAt: '2026-10-22T00:30:00Z'),
    );
    expect(archived.archived, isTrue);
    expect(archived.archivedAt, DateTime.utc(2026, 10, 22, 0, 30));
    expect(TreasuryWire.reportFromJson(_json()).archived, isFalse);
  });

  testWidgets('un rapport archivé porte sa pastille', (tester) async {
    setTestWindow(tester, const Size(1280, 600));
    await tester.pumpWidget(
      treasuryHost(
        ReportsTable(
          reports: [TreasuryWire.reportFromJson(_json(archived: true))],
          today: demoDay,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Archivé'), findsOneWidget);
    expect(find.text('Définitif'), findsOneWidget);
    // Le tableau : bandeau terre cuite et ses quatre colonnes.
    expect(find.text('RAPPORT'), findsOneWidget);
    expect(find.text('CONSULTER'), findsOneWidget);
    expect(find.text('21 oct. 2026'), findsOneWidget);
  });

  testWidgets('sans archive, pas de pastille', (tester) async {
    setTestWindow(tester, const Size(1280, 600));
    await tester.pumpWidget(
      treasuryHost(ReportsTable(reports: [cashReport()], today: demoDay)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Archivé'), findsNothing);
  });
}
