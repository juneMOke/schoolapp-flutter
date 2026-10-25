import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

/// Le barème élargi du back (Q8) : rangé une fois servi, tu sinon — une
/// tablette au cache ancien ne rallume pas, par ses défauts, la PC/E d'une
/// école qui l'a coupée.
const _school = 's-1';

Map<String, dynamic> _section({bool wide = true}) => {
  'monthlyHoursDivisor': 173,
  'overtimeMultiplierPermille': 1300,
  'allowanceEligibleKinds': ['PERMANENT'],
  'currencyRules': [
    {
      'currency': 'USD',
      'childAllowanceInCents': 500,
      'defaultOvertimeRateInCents': 300,
      'overtimeRateStepInCents': 50,
    },
  ],
  if (wide) ...{
    'cnssEmployerPermille': 120,
    'inppPermille': 20,
    'onemPermille': 2,
    'advanceMaxPercent': 40,
    'loanMaxMonths': 6,
    'childcareEnabled': false,
    'signatureBeneficiaryLabel': 'L’agent',
    'signatureDirectorLabel': '',
    'signatureCashierLabel': 'Économe',
  },
};

void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  Future<Map<String, dynamic>> savedWire(PayrollSettingsSeed seed) async {
    final dao = PayrollSettingsDao(db);
    await dao.applySeed(seed, schoolId: _school, nowMs: 1);
    final settings = await dao.read(_school);
    return PayrollSettingsDao.toSeed(settings).toJson();
  }

  test('servi : rangé, relu, et remonté tel quel', () async {
    final seed = PayrollSettingsSeed.tryParse(_section())!;
    final settings = await () async {
      await PayrollSettingsDao(db).applySeed(seed, schoolId: _school, nowMs: 1);
      return PayrollSettingsDao(db).read(_school);
    }();

    expect(settings.wideSettingsServed, isTrue);
    expect(settings.childcareEnabled, isFalse);
    expect(settings.loanMaxMonths, 6);
    expect(settings.employerChargesPermille, 142);
    expect(settings.signatureDirectorLabel, isNull);

    final wire = await savedWire(seed);
    expect(wire['childcareEnabled'], false);
    expect(wire['advanceMaxPercent'], 40);
    // Un intitulé vide revient à celui du modèle papier.
    expect(wire['signatureDirectorLabel'], '');
    expect(wire['signatureCashierLabel'], 'Économe');
  });

  test('pas servi : défauts en mémoire, rien remonté', () async {
    final seed = PayrollSettingsSeed.tryParse(_section(wide: false))!;
    expect(seed.servesWideSettings, isFalse);

    final wire = await savedWire(seed);
    final settings = await PayrollSettingsDao(db).read(_school);
    expect(settings.wideSettingsServed, isFalse);
    expect(settings.childcareEnabled, isTrue);
    expect(settings.loanMaxMonths, 4);
    for (final key in [
      'cnssEmployerPermille',
      'advanceMaxPercent',
      'loanMaxMonths',
      'childcareEnabled',
      'signatureBeneficiaryLabel',
    ]) {
      expect(wire.containsKey(key), isFalse, reason: key);
    }
  });

  test('la remontée porte le barème élargi dans `settings`', () {
    final request = PayrollSettingsRequestDto(
      settings: PayrollSettingsSeed.tryParse(_section())!,
      clientUpdatedAt: '2026-10-25T10:00:00.000Z',
      authorId: 'u-1',
    );
    final json = request.toJson()['settings'] as Map;
    expect(json['loanMaxMonths'], 6);
    expect(
      PayrollSettingsRequestDto.tryParse(
        request.toJson(),
      )!.settings.childcareEnabled,
      isFalse,
    );
  });

  test(
    'un enregistrement sans barème élargi n efface pas celui rangé',
    () async {
      final dao = PayrollSettingsDao(db);
      await dao.applySeed(
        PayrollSettingsSeed.tryParse(_section())!,
        schoolId: _school,
        nowMs: 1,
      );

      // L'écran ouvert avant le pull n'avait pas le barème élargi.
      await dao.save(
        PayrollSettingsRequestDto(
          settings: PayrollSettingsSeed.tryParse(_section(wide: false))!,
          clientUpdatedAt: '2026-10-25T11:00:00.000Z',
          authorId: 'u-1',
        ),
        schoolId: _school,
        nowMs: 2,
      );

      final settings = await dao.read(_school);
      expect(settings.wideSettingsServed, isTrue);
      expect(settings.childcareEnabled, isFalse);
      expect(settings.loanMaxMonths, 6);
    },
  );
}
