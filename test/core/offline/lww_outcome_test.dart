import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/lww_outcome.dart';

void main() {
  test('lit les deux verdicts du contrat, rien d\'autre', () {
    expect(LwwOutcome.fromWire('APPLIED'), LwwOutcome.applied);
    expect(LwwOutcome.fromWire('SUPERSEDED'), LwwOutcome.superseded);
    expect(LwwOutcome.fromWire('IGNORED'), isNull);
    expect(LwwOutcome.fromWire(null), isNull);
  });
}
