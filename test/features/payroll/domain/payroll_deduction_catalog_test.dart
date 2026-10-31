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
}) => PayrollDeductionType(
  id: id,
  label: label ?? id,
  sortOrder: order,
  archived: archived,
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
      ], 'Cartes');

      final type = saved().single;
      expect(type.id, 'new');
      expect(type.sortOrder, 40);
    });

    test('libellé pris, sans la casse ni les bordures', () async {
      final result = await CreatePayrollDeductionTypeUseCase(repository)([
        _type('a', label: 'Frais des cartes'),
      ], '  FRAIS des CARTES ');

      expect(_rule(result), PayrollRule.deductionTypeLabelTaken);
      verifyNever(() => repository.saveTypes(any()));
    });

    test('un libellé archivé se réutilise', () async {
      final result = await CreatePayrollDeductionTypeUseCase(repository)([
        _type('a', label: 'Cartes', archived: true),
      ], 'Cartes');

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('vide ou trop long : refusé', () async {
      final useCase = CreatePayrollDeductionTypeUseCase(repository);

      expect(_rule(await useCase(const [], '  ')), PayrollRule.invalidData);
      expect(_rule(await useCase(const [], 'x' * 41)), PayrollRule.invalidData);
    });

    test('six actives au plus, les archivées ne comptent pas', () async {
      final six = [for (var i = 0; i < 6; i++) _type('t$i')];
      final useCase = CreatePayrollDeductionTypeUseCase(repository);

      expect(
        _rule(await useCase(six, 'Autre')),
        PayrollRule.deductionTypeLimitReached,
      );
      expect(
        await useCase([...six.skip(1), _type('old', archived: true)], 'Autre'),
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
