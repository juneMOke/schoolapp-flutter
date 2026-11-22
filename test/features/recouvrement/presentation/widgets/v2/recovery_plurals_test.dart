import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En français, la catégorie ICU `one` couvre 0 **et** 1 : sans `=0`
/// explicite, « 0 » tombait dans la forme du singulier (« Exporter cet
/// élève » sur un onglet vide, « 1 élève » dit pour 0).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('0 n\'est jamais lu au singulier, ni comme « 1 »', () {
    final zero = <String>[
      fr.recouvrementFeesMore(0),
      fr.recouvrementFeesCheckedFooter(0),
      fr.recoveryPerimeterFooter(0),
      fr.recoveryClassSheetSubtitle(0, '05/09/2026'),
      fr.recoveryStudentsExportLead(0),
      fr.recoveryFiguresSettledSubline(0),
      fr.recoveryFiguresRemainingSubline(0),
      fr.recoveryFiguresSituationTitle(0),
      fr.recoveryFiguresSituationRowA11y('Soldé', 0),
      fr.recoverySimulationShowMore(0),
      fr.recoveryInsightSimulationUnmanageable(0, 60),
      fr.feeControlNotifyTitle(0),
      fr.feeControlNotifyCharacterCount(0),
      fr.feeControlNotifySent(0),
    ];
    for (final text in zero) {
      expect(text, isNot(contains('1 ')), reason: text);
      expect(text, isNot(contains('cet élève')), reason: text);
      expect(text, isNot(contains("l'élève")), reason: text);
      expect(text, isNot(contains("l'autre classe")), reason: text);
    }
    expect(fr.recoveryStudentsExportLead(0), 'Aucun élève à exporter');
    expect(
      fr.recoveryFiguresSituationRowA11y('Soldé', 0),
      'Soldé : aucun élève',
    );
    expect(fr.feeControlNotifyTitle(0), 'Aucun parent à notifier');
    expect(fr.feeControlNotifySent(0), 'Aucune relance envoyée.');
  });

  test('1 et plusieurs : le compte vient de {count}', () {
    expect(fr.recoveryStudentsExportLead(1), 'Exporter cet élève');
    expect(fr.recoveryStudentsExportLead(3), 'Exporter ces 3 élèves');
    expect(fr.recoveryFiguresSituationRowA11y('Soldé', 1), 'Soldé : 1 élève');
    expect(fr.recoveryFiguresSituationRowA11y('Soldé', 4), 'Soldé : 4 élèves');
    expect(fr.feeControlNotifyTitle(1), 'Notifier 1 parent');
    expect(fr.feeControlNotifySent(2), 'Relance envoyée à 2 parents.');
  });

  test('en anglais aussi, 0 a sa forme', () {
    expect(en.recoveryStudentsExportLead(0), 'No student to export');
    expect(en.recoveryFiguresSituationTitle(0), 'No students');
    expect(en.feeControlNotifyTitle(0), 'No parent to notify');
  });
}
