import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_local.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_request_factory.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_snapshot_reader.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_local_writer.dart';

/// La paie sur la tablette : lecture locale ([PayrollSnapshotReader]),
/// écriture en outbox, chaque écriture avec son entrée dans une transaction.
class PayrollRepositoryImpl implements PayrollRepository {
  final PayrollSnapshotReader _reader;
  final PayrollLocal _local;
  final StaffLocalWriter _writer;
  final IdGenerator _ids;
  final DateTime Function() _now;

  const PayrollRepositoryImpl({
    required PayrollSnapshotReader reader,
    required PayrollLocal local,
    required StaffLocalWriter writer,
    required IdGenerator ids,
    DateTime Function() now = DateTime.now,
  }) : _reader = reader,
       _local = local,
       _writer = writer,
       _ids = ids,
       _now = now;

  @override
  Future<Either<Failure, PayrollSnapshot>> load() async {
    final session = _writer.session();
    if (session == null) return const Right(PayrollSnapshot.empty);
    return _reader.read(session.schoolId);
  }

  /// Une écriture : la session, l'horloge, puis [write] sous le nom [what].
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
  Future<Either<Failure, Unit>> saveVariables(
    String month,
    PayrollVariables variables,
  ) => _write(
    'Écriture des éléments variables',
    (requests, nowMs) => _local.variables.save(
      requests.variables(month, variables),
      schoolId: requests.schoolId,
      nowMs: nowMs,
    ),
  );

  @override
  Future<Either<Failure, Unit>> recordGesture(
    String month,
    PayrollGestureKind kind, {
    String? reason,
    PayrollFingerprint? expected,
  }) => _write(
    'Écriture du geste',
    (requests, nowMs) => _local.gestures.add(
      requests.gesture(month, kind, reason: reason, expected: expected),
      schoolId: requests.schoolId,
      nowMs: nowMs,
    ),
  );

  @override
  Future<Either<Failure, Unit>> saveProfile(StaffPayProfile profile) => _write(
    'Écriture du profil de paie',
    (requests, nowMs) => _local.profiles.save(
      requests.profile(profile),
      schoolId: requests.schoolId,
      nowMs: nowMs,
    ),
  );

  @override
  Future<Either<Failure, Unit>> saveSettings(PayrollSettings settings) =>
      _write(
        'Écriture des réglages de paie',
        (requests, nowMs) => _local.settings.save(
          PayrollSettingsRequestDto(
            settings: PayrollSettingsDao.toSeed(settings),
            clientUpdatedAt: requests.stamp,
            authorId: requests.authorId,
          ),
          schoolId: requests.schoolId,
          nowMs: nowMs,
        ),
      );

  @override
  Future<Either<Failure, Unit>> grantAdvance(SalaryAdvanceDraft draft) =>
      _write(
        "Écriture de l'avance",
        (requests, nowMs) => _local.advances.add(
          requests.advance(draft),
          schoolId: requests.schoolId,
          nowMs: nowMs,
        ),
      );

  @override
  Future<Either<Failure, Unit>> cancelAdvance(
    String advanceId,
    String reason,
  ) => _write(
    "Annulation de l'avance",
    (requests, nowMs) => _local.advances.cancel(
      requests.cancellation(
        PayrollCancellationRequestDto.advanceKey,
        advanceId,
        reason,
      ),
      schoolId: requests.schoolId,
      nowMs: nowMs,
    ),
  );

  @override
  Future<Either<Failure, Unit>> disburse(PayrollDisbursementDraft draft) async {
    if (await _local.disbursements.hasLive(draft.month, draft.staffMemberId)) {
      return Left(PayrollRuleFailure(PayrollRule.alreadyDisbursed));
    }
    return _write(
      'Écriture du versement',
      (requests, nowMs) => _local.disbursements.add(
        requests.disbursement(draft),
        schoolId: requests.schoolId,
        nowMs: nowMs,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> cancelDisbursement(
    PayrollDisbursement disbursement,
    String reason,
  ) => _write(
    'Annulation du versement',
    (requests, nowMs) => _local.disbursements.cancel(
      requests.cancellation(
        PayrollCancellationRequestDto.disbursementKey,
        disbursement.id,
        reason,
      ),
      month: disbursement.month,
      staffMemberId: disbursement.staffMemberId,
      schoolId: requests.schoolId,
      nowMs: nowMs,
    ),
  );

  @override
  Future<Either<Failure, Unit>> recordShare(
    String month,
    String staffMemberId,
    PayrollShareChannel channel,
  ) async {
    final session = _writer.session();
    if (session == null) return const Left(StaffLocalWriter.noSession);
    try {
      await _local.shares.record(
        schoolId: session.schoolId,
        month: month,
        staffMemberId: staffMemberId,
        channel: channel,
        sharedAt: _now().toUtc().toIso8601String(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Trace de diffusion : $e'));
    }
  }
}
