import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

void main() {
  const intent = FeeControlIntent(
    schoolLevelGroupId: 'g1',
    schoolLevelId: 'lvl-1',
    classroomId: 'c-2',
    feeCode: 'TUITION',
  );

  test('extra prime sur l’adresse', () {
    expect(FeeControlIntent.fromRoute(intent, const {'fee': 'OTHER'}), intent);
  });

  test('l’adresse seule reconstruit le périmètre', () {
    expect(
      FeeControlIntent.fromRoute(null, intent.toQueryParameters()),
      intent,
    );
  });

  test('sans classe, la clé est absente et l’intention vise le niveau', () {
    const level = FeeControlIntent(
      schoolLevelGroupId: 'g1',
      schoolLevelId: 'lvl-1',
      feeCode: 'TUITION',
    );
    expect(level.toQueryParameters().containsKey('classroom'), isFalse);
    expect(FeeControlIntent.fromRoute(null, level.toQueryParameters()), level);
  });

  test('une adresse incomplète ouvre l’écran vierge', () {
    expect(
      FeeControlIntent.fromRoute(null, const {'cycle': 'g1', 'fee': 'X'}),
      isNull,
    );
    expect(FeeControlIntent.fromRoute(null), isNull);
  });
}
