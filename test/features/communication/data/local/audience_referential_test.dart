import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/data/local/audience_referential_repository_impl.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

LocalFeeTariff _t(String id, String feeCode, {String? code, String? label}) =>
    LocalFeeTariff(
      id: id,
      feeCode: feeCode,
      code: code,
      label: label ?? '$feeCode $code',
      amountInCents: 100,
      currency: 'USD',
      version: 0,
    );

void main() {
  test(
    'une entrée par nature ; les tranches qui distinguent, une fois chacune',
    () {
      final natures = AudienceReferentialRepositoryImpl.natures([
        _t('1', 'TUITION', code: 'T1', label: 'Minerval 1/3'),
        _t('2', 'TUITION', code: 'T2', label: 'Minerval 2/3'),
        // Le même T1 sur un autre niveau : une seule tranche.
        _t('3', 'TUITION', code: 'T1', label: 'Minerval 1/3 (secondaire)'),
        _t('4', 'TRANSPORT', code: 'TRANSPORT', label: 'Transport'),
      ]);
      expect(natures.map((n) => n.feeCode), ['TUITION', 'TRANSPORT']);
      expect(natures.first.tranches, const [
        OverdueFeeTranche(code: 'T1', label: 'Minerval 1/3'),
        OverdueFeeTranche(code: 'T2', label: 'Minerval 2/3'),
      ]);
      expect(natures.first.singleLabel, isNull);
      // Un code égal à la nature ne distingue rien : aucune tranche.
      expect(natures.last.tranches, isEmpty);
      expect(natures.last.singleLabel, 'Transport');
    },
  );
}
