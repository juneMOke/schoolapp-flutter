import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/domain/services/report_signatory_rules.dart';

ReportSignatory _s({
  int rank = 1,
  String caption = 'ÉTABLI PAR',
  String? name,
  String function = 'Caissière',
  bool closer = false,
}) => ReportSignatory(
  rank: rank,
  caption: caption,
  name: name,
  function: function,
  filledByCloser: closer,
);

void main() {
  test('textes rognés ; un nom blanc vaut null ; rangs 1..n', () {
    final out = ReportSignatoryRules.trimmed([
      _s(rank: 3, caption: '  ÉTABLI PAR ', name: '   '),
      _s(rank: 7, name: ' MWAMBA Paul ', function: ' Préfet '),
    ]);
    expect(out.map((s) => s.rank), [1, 2]);
    expect(out.first.caption, 'ÉTABLI PAR');
    expect(out.first.name, isNull);
    expect(out.last.name, 'MWAMBA Paul');
    expect(out.last.function, 'Préfet');
  });

  test('« la personne qui a clôturé » ne survit qu au premier rang', () {
    final out = ReportSignatoryRules.renumbered([
      _s(),
      _s(rank: 2, closer: true),
    ]);
    expect(out.map((s) => s.filledByCloser), [false, false]);
  });

  test('liste valide : 4 au plus, légende et fonction requises', () {
    expect(ReportSignatoryRules.isListValid(const []), isTrue);
    expect(ReportSignatoryRules.isListValid([_s(closer: true)]), isTrue);
    expect(ReportSignatoryRules.isListValid(List.filled(5, _s())), isFalse);
    expect(ReportSignatoryRules.isListValid([_s(caption: '  ')]), isFalse);
    expect(ReportSignatoryRules.isListValid([_s(function: '')]), isFalse);
    expect(ReportSignatoryRules.isListValid([_s(caption: 'A' * 41)]), isFalse);
    expect(ReportSignatoryRules.isListValid([_s(), _s(closer: true)]), isFalse);
  });
}
