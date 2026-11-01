import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_local.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_request_factory.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_deduction_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_local_writer.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';

/// Écriture en outbox, sauf la suppression d'une rubrique que le serveur
/// connaît : elle part en ligne, pour que son refus se lise tout de suite.
class PayrollDeductionRepositoryImpl implements PayrollDeductionRepository {
  final PayrollLocal _local;
  final StaffLocalWriter _writer;
  final PayrollSyncApi _api;
  final Map<String, dynamic> _extras;
  final IdGenerator _ids;
  final DateTime Function() _now;

  const PayrollDeductionRepositoryImpl({
    required PayrollLocal local,
    required StaffLocalWriter writer,
    required PayrollSyncApi api,
    required Map<String, dynamic> extras,
    required IdGenerator ids,
    DateTime Function() now = DateTime.now,
  }) : _local = local,
       _writer = writer,
       _api = api,
       _extras = extras,
       _ids = ids,
       _now = now;

  @override
  String newTypeId() => _ids.newId();

  Future<Either<Failure, Unit>> _write(
    String what,
    Future<void> Function(PayrollRequestFactory requests, int nowMs) write,
  ) async {
    final session = _writer.session();
    if (session == null) return const Left(StaffLocalWriter.noSession);
    final now = _now();
    return _writer.run(
      what,
      () => write(
        PayrollRequestFactory(
          authorId: session.authorId,
          stamp: now.toUtc().toIso8601String(),
          ids: _ids,
          schoolId: session.schoolId,
        ),
        now.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> saveTypes(List<PayrollDeductionType> types) =>
      _write(
        'Écriture des rubriques',
        (requests, nowMs) => _local.deductionTypes.saveAll(
          [for (final type in types) requests.deductionType(type)],
          schoolId: requests.schoolId,
          nowMs: nowMs,
        ),
      );

  @override
  Future<Either<Failure, Unit>> saveEntries(
    String month, {
    PayrollVariables? variables,
    List<PayrollDeductionEntry> entries = const [],
  }) => _write(
    'Écriture des retenues',
    (requests, nowMs) => _local.deductions.saveWithVariables(
      variables == null ? null : requests.variables(month, variables),
      [for (final entry in entries) requests.deduction(month, entry)],
      schoolId: requests.schoolId,
      nowMs: nowMs,
    ),
  );

  @override
  Future<Either<Failure, Unit>> dismissEntry(
    String month,
    PayrollDeductionEntry entry,
  ) async {
    final session = _writer.session();
    if (session == null) return const Left(StaffLocalWriter.noSession);
    return _writer.run(
      'Effacement d\'une retenue refusée',
      () => _local.deductions.dismiss(month, entry, schoolId: session.schoolId),
    );
  }

  @override
  Future<Either<Failure, Unit>> removeType(String id) async {
    final session = _writer.session();
    if (session == null) return const Left(StaffLocalWriter.noSession);
    final schoolId = session.schoolId;
    try {
      if (!await _local.deductionTypes.isServerKnown(schoolId, id)) {
        await _local.deductionTypes.cancelUnsent(schoolId, id);
        return const Right(unit);
      }
      // Le serveur ne la voit pas : il accepterait, et la saisie reviendrait
      // en pierre tombale.
      if (await _local.deductions.hasQueuedOn(id)) {
        return Left(PayrollRuleFailure(PayrollRule.deductionTypeInUse));
      }
      await _api.deleteDeductionType(_extras, id);
      await _local.deductionTypes.remove(schoolId, id);
      return const Right(unit);
    } on DioException catch (e) {
      return await _removeFailure(e, schoolId, id);
    } catch (e) {
      return Left(StorageFailure('Suppression de la rubrique : $e'));
    }
  }

  Future<Either<Failure, Unit>> _removeFailure(
    DioException e,
    String schoolId,
    String id,
  ) async {
    final failure = StaffPushFailure.of(e);
    if (failure.isTombstoned) {
      await _local.deductionTypes.remove(schoolId, id);
      return const Right(unit);
    }
    if (failure.detailCode == PayrollDeductionCodes.inUse) {
      return Left(PayrollRuleFailure(PayrollRule.deductionTypeInUse));
    }
    if (failure.status == null) return const Left(NetworkFailure());
    if (failure.status == 403) {
      return Left(PayrollRuleFailure(PayrollRule.forbidden));
    }
    return Left(ServerFailure(failure.reason));
  }
}

/// Le contrat tient le libellé sans espaces de bordure, et une description vide
/// pour absente.
extension PayrollDeductionRequests on PayrollRequestFactory {
  PayrollDeductionTypeRequestDto deductionType(PayrollDeductionType type) =>
      PayrollDeductionTypeRequestDto(
        id: type.id,
        code: type.code,
        label: type.label.trim(),
        description: switch (type.description?.trim()) {
          final text? when text.isNotEmpty => text,
          _ => null,
        },
        currency: type.currency,
        defaultAmountInCents: type.defaultAmountInCents,
        sortOrder: type.sortOrder,
        archived: type.archived,
        clientUpdatedAt: stamp,
        authorId: authorId,
      );

  PayrollDeductionRequestDto deduction(
    String month,
    PayrollDeductionEntry entry,
  ) => PayrollDeductionRequestDto(
    month: month,
    staffMemberId: entry.staffMemberId,
    deductionTypeId: entry.deductionTypeId,
    amountInCents: entry.amountInCents,
    currency: entry.currency,
    clientUpdatedAt: stamp,
    authorId: authorId,
  );
}
