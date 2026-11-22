import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

/// La question du contrôle des frais tenue dans l'adresse (spec v2, §0 « Ce
/// que l'adresse retient ») : frais, classe, situation et montant.
void main() {
  const intent = FeeControlIntent(
    classroomId: 'c-2',
    feeCodes: ['TUITION', 'BOOKS'],
    situation: FeeControlPaymentFilter.partial,
  );

  test('extra prime sur l’adresse', () {
    expect(
      FeeControlIntent.fromRoute(intent, const {'frais': 'OTHER'}),
      intent,
    );
  });

  test(
    'aller-retour par l’adresse : frais (dans l’ordre), classe, situation',
    () {
      final params = intent.toQueryParameters();
      expect(params['frais'], 'TUITION,BOOKS');
      expect(params['classe'], 'c-2');
      expect(params['situation'], 'partiel');
      expect(FeeControlIntent.fromRoute(null, params), intent);
    },
  );

  test('« a payé au moins » garde son montant, en centimes', () {
    const atLeast = FeeControlIntent(
      classroomId: 'c-2',
      feeCodes: ['TUITION'],
      situation: FeeControlPaymentFilter.threshold,
      thresholdInCents: 15000,
    );
    final params = atLeast.toQueryParameters();
    expect(params['situation'], 'au-moins');
    expect(params['montant'], '15000');
    expect(FeeControlIntent.fromRoute(null, params), atLeast);
  });

  test('le montant ne s’écrit pas hors du segment « au moins »', () {
    const partial = FeeControlIntent(
      feeCodes: ['TUITION'],
      situation: FeeControlPaymentFilter.partial,
      thresholdInCents: 15000,
    );
    expect(partial.toQueryParameters().containsKey('montant'), isFalse);
  });

  test('« Tous » est le défaut : la clé de situation est absente', () {
    const all = FeeControlIntent(feeCodes: ['TUITION']);
    expect(all.toQueryParameters().containsKey('situation'), isFalse);
    expect(all.toQueryParameters().containsKey('classe'), isFalse);
    expect(FeeControlIntent.fromRoute(null, all.toQueryParameters()), all);
  });

  test('la rubrique « Non affectés » voyage par sa valeur de fil', () {
    const unassigned = FeeControlIntent(
      classroomId: feeControlUnassigned,
      feeCodes: ['TUITION'],
    );
    expect(unassigned.toQueryParameters()['classe'], 'UNASSIGNED');
    expect(
      FeeControlIntent.fromRoute(null, unassigned.toQueryParameters()),
      unassigned,
    );
  });

  test('une adresse sans frais ne porte aucune question', () {
    expect(FeeControlIntent.fromRoute(null, const {'classe': 'c-2'}), isNull);
    expect(FeeControlIntent.fromRoute(null, const {'frais': ' , '}), isNull);
    expect(FeeControlIntent.fromRoute(null), isNull);
  });

  test('une situation ou un montant illisible retombe sur le défaut', () {
    final read = FeeControlIntent.fromRoute(null, const {
      'frais': 'TUITION',
      'situation': 'n-importe-quoi',
      'montant': '-5',
    });
    expect(read?.situation, FeeControlPaymentFilter.all);
    expect(read?.thresholdInCents, isNull);
  });
}
