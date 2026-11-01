import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_deduction_use_cases.dart';

class _MockRepository extends Mock implements PayrollDeductionRepository {}

PayrollDeductionType _type(
  String id, {
  String? label,
  int order = 10,
  bool archived = false,
  String? code,
  String currency = 'USD',
}) => PayrollDeductionType(
  id: id,
  code: code ?? 'C-${id.toUpperCase()}',
  label: label ?? id,
  currency: currency,
  sortOrder: order,
  archived: archived,
);

PayrollDeductionTypeDraft _draft(
  String label, {
  String code = 'CARTE',
  String currency = 'USD',
  int defaultAmount = 0,
  String? description,
}) => PayrollDeductionTypeDraft(
  code: code,
  label: label,
  description: description,
  currency: currency,
  defaultAmountInCents: defaultAmount,
);

PayrollRule? _rule(Either<Failure, Unit> result) =>
    result.fold((failure) => (failure as PayrollRuleFailure).rule, (_) => null);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(<PayrollDeductionType>[]));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.newTypeId()).thenReturn('new');
    when(
      () => repository.saveTypes(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  List<PayrollDeductionType> saved() =>
      verify(() => repository.saveTypes(captureAny())).captured.single
          as List<PayrollDeductionType>;

  group('création', () {
    test('en fin de liste, identifiant de la tablette', () async {
      await CreatePayrollDeductionTypeUseCase(repository)([
        _type('a', order: 30),
      ], _draft('Cartes', defaultAmount: 500, description: 'Badge'));

      final type = saved().single;
      expect(type.id, 'new');
      expect(type.sortOrder, 40);
      expect(type.code, 'CARTE');
      expect(type.currency, 'USD');
      expect(type.defaultAmountInCents, 500);
      expect(type.description, 'Badge');
    });

    test(
      'libellé pris dans la devise, sans la casse ni les bordures',
      () async {
        final result = await CreatePayrollDeductionTypeUseCase(repository)([
          _type('a', label: 'Frais des cartes'),
        ], _draft('  FRAIS des CARTES '));

        expect(_rule(result), PayrollRule.deductionTypeLabelTaken);
        verifyNever(() => repository.saveTypes(any()));
      },
    );

    test('le même libellé dans une autre devise passe (C2)', () async {
      final result = await CreatePayrollDeductionTypeUseCase(repository)([
        _type('a', label: 'Cartes'),
      ], _draft('Cartes', currency: 'CDF'));

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('un libellé archivé se réutilise', () async {
      final result = await CreatePayrollDeductionTypeUseCase(repository)([
        _type('a', label: 'Cartes', archived: true),
      ], _draft('Cartes'));

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('vide ou trop long : refusé', () async {
      final useCase = CreatePayrollDeductionTypeUseCase(repository);

      expect(
        _rule(await useCase(const [], _draft('  '))),
        PayrollRule.invalidData,
      );
      expect(
        _rule(await useCase(const [], _draft('x' * 41))),
        PayrollRule.invalidData,
      );
    });

    test('code mal formé, devise absente, description trop longue', () async {
      final useCase = CreatePayrollDeductionTypeUseCase(repository);

      for (final draft in [
        _draft('A', code: 'x'),
        _draft('A', code: 'carte'),
        _draft('A', code: 'TROP-LONG-CODE'),
        _draft('A', currency: ''),
        _draft('A', description: 'x' * 201),
      ]) {
        expect(_rule(await useCase(const [], draft)), PayrollRule.invalidData);
      }
    });

    test('un défaut négatif est refusé, 0 passe', () async {
      final useCase = CreatePayrollDeductionTypeUseCase(repository);

      expect(
        _rule(await useCase(const [], _draft('A', defaultAmount: -1))),
        PayrollRule.invalidAmount,
      );
      expect(
        await useCase(const [], _draft('A')),
        const Right<Failure, Unit>(unit),
      );
    });

    test('un code reste pris, même par une rubrique archivée', () async {
      final result = await CreatePayrollDeductionTypeUseCase(repository)([
        _type('a', code: 'CARTE', archived: true, currency: 'CDF'),
      ], _draft('Autre'));

      expect(_rule(result), PayrollRule.deductionTypeCodeTaken);
    });

    test('six actives par devise, les archivées ne comptent pas', () async {
      final six = [for (var i = 0; i < 6; i++) _type('t$i')];
      final useCase = CreatePayrollDeductionTypeUseCase(repository);

      expect(
        _rule(await useCase(six, _draft('Autre'))),
        PayrollRule.deductionTypeLimitReached,
      );
      expect(
        await useCase(six, _draft('Autre', currency: 'CDF')),
        const Right<Failure, Unit>(unit),
      );
      expect(
        await useCase([
          ...six.skip(1),
          _type('old', archived: true),
        ], _draft('Autre')),
        const Right<Failure, Unit>(unit),
      );
    });
  });

  group('mise à jour', () {
    test('renommer sa propre rubrique ne se heurte pas à elle-même', () async {
      expect(
        await UpdatePayrollDeductionTypeUseCase(repository)([
          _type('a', label: 'Cartes'),
        ], _type('a', label: 'CARTES')),
        const Right<Failure, Unit>(unit),
      );
    });

    test('une rubrique utilisée garde son code et sa devise', () async {
      final useCase = UpdatePayrollDeductionTypeUseCase(repository);
      final catalog = [_type('a')];

      for (final changed in [
        _type('a', code: 'AUTRE'),
        _type('a', currency: 'CDF'),
      ]) {
        expect(
          _rule(await useCase(catalog, changed, used: true)),
          PayrollRule.deductionTypeFieldLocked,
        );
      }
      expect(
        await useCase(catalog, _type('a', code: 'AUTRE')),
        const Right<Failure, Unit>(unit),
      );
      expect(
        await useCase(catalog, _type('a', label: 'Neuf'), used: true),
        const Right<Failure, Unit>(unit),
      );
    });

    test('une rubrique sans code ni devise se gère encore', () async {
      final useCase = UpdatePayrollDeductionTypeUseCase(repository);
      const legacy = PayrollDeductionType(id: 'a', label: 'A', sortOrder: 10);

      expect(
        await useCase(
          const [legacy],
          legacy.rewritten(archived: true),
          used: true,
        ),
        const Right<Failure, Unit>(unit),
      );
      expect(
        await useCase(
          const [legacy],
          legacy.rewritten(draft: _draft('A', code: 'NOUVEAU')),
          used: true,
        ),
        const Right<Failure, Unit>(unit),
      );
    });

    test('archiver passe toujours', () async {
      final six = [for (var i = 0; i < 6; i++) _type('t$i')];

      expect(
        await UpdatePayrollDeductionTypeUseCase(repository)(
          six,
          _type('t0', archived: true),
        ),
        const Right<Failure, Unit>(unit),
      );
    });

    test('restaurer repasse par le libellé et le plafond', () async {
      final useCase = UpdatePayrollDeductionTypeUseCase(repository);
      final archived = _type('old', label: 'Cartes', archived: true);
      final restored = _type('old', label: 'Cartes');

      expect(
        _rule(await useCase([archived, _type('a', label: 'Cartes')], restored)),
        PayrollRule.deductionTypeLabelTaken,
      );
      expect(
        _rule(
          await useCase([
            archived,
            for (var i = 0; i < 6; i++) _type('t$i'),
          ], restored),
        ),
        PayrollRule.deductionTypeLimitReached,
      );
    });
  });

  group('déplacement', () {
    final catalog = [
      _type('a', order: 10),
      _type('b', order: 20),
      _type('c', order: 30),
    ];

    test('seuls les rangs qui changent repartent', () async {
      await MovePayrollDeductionTypeUseCase(repository)(catalog, 'b', up: true);

      expect({for (final t in saved()) t.id: t.sortOrder}, {'b': 10, 'a': 20});
    });

    test('déplacer garde toute la fiche', () async {
      await MovePayrollDeductionTypeUseCase(repository)(
        [
          _type('a', order: 10),
          const PayrollDeductionType(
            id: 'b',
            code: 'B1',
            label: 'B',
            description: 'Note',
            currency: 'CDF',
            defaultAmountInCents: 700,
            sortOrder: 20,
          ),
        ],
        'b',
        up: true,
      );

      final moved = saved().firstWhere((type) => type.id == 'b');
      expect(moved.code, 'B1');
      expect(moved.description, 'Note');
      expect(moved.currency, 'CDF');
      expect(moved.defaultAmountInCents, 700);
    });

    test('aux bornes, rien ne part', () async {
      final useCase = MovePayrollDeductionTypeUseCase(repository);

      await useCase(catalog, 'a', up: true);
      await useCase(catalog, 'c', up: false);

      verifyNever(() => repository.saveTypes(any()));
    });

    test('des rangs égaux se renumérotent', () async {
      await MovePayrollDeductionTypeUseCase(repository)(
        [_type('a', order: 10), _type('b', order: 10)],
        'b',
        up: true,
      );

      expect({for (final t in saved()) t.id: t.sortOrder}, {'a': 20});
    });
  });
}
