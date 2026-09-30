import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_contract_input_mapper.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_contract_repository.dart';

/// Les contrats sur la tablette : lecture locale, écriture en outbox.
class StaffContractRepositoryImpl implements StaffContractRepository {
  final StaffContractDao _contracts;
  final StaffContractWriteDao _writer;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;

  /// Relance le flush après un geste ; `null` dans les tests qui n'en ont pas
  /// besoin.
  final SyncEngine? _syncEngine;
  final DateTime Function() _now;

  const StaffContractRepositoryImpl({
    required StaffContractDao contracts,
    required StaffContractWriteDao writer,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
    SyncEngine? syncEngine,
    DateTime Function() now = DateTime.now,
  }) : _contracts = contracts,
       _writer = writer,
       _currentUser = currentUser,
       _ids = ids,
       _syncEngine = syncEngine,
       _now = now;

  @override
  Future<Either<Failure, List<StaffContract>>> contractsOf(
    String staffMemberId,
  ) async {
    try {
      return Right([
        for (final row in await _contracts.forMember(staffMemberId))
          row.toEntity(),
      ]);
    } catch (e) {
      return Left(StorageFailure('Lecture des contrats : $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addContract(
    String staffMemberId,
    StaffContractDraft draft,
  ) async {
    final session = _session();
    if (session == null) return const Left(_noSession);
    final now = _now();
    final input = StaffContractInputMapper.of(
      draft,
      id: _ids.newId(),
      recordedAt: now.toUtc().toIso8601String(),
    );
    if (input == null) return const Left(_incomplete);
    return _write(
      () => _writer.addContract(
        request: StaffContractSyncRequestDto(
          staffMemberId: staffMemberId,
          contract: input,
          authorId: session.authorId,
        ),
        schoolId: session.schoolId,
        nowMs: now.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> correctContract(
    StaffContract original, {
    required String reason,
    StaffContractDraft? replacement,
  }) async {
    final session = _session();
    if (session == null) return const Left(_noSession);
    if (original.isCorrected) {
      return const Left(ValidationFailure('Période déjà corrigée'));
    }
    final now = _now();
    final stamp = now.toUtc().toIso8601String();
    StaffContractInputDto? input;
    if (replacement != null) {
      input = StaffContractInputMapper.of(
        replacement,
        id: _ids.newId(),
        recordedAt: stamp,
      );
      if (input == null) return const Left(_incomplete);
    }
    final trimmed = reason.trim();
    return _write(
      () => _writer.correct(
        request: StaffContractCorrectionRequestDto(
          correctionId: _ids.newId(),
          contractId: original.id,
          staffMemberId: original.staffMemberId,
          reason: trimmed.isEmpty ? null : trimmed,
          correctedAt: stamp,
          replacement: input,
          authorId: session.authorId,
        ),
        schoolId: session.schoolId,
        nowMs: now.millisecondsSinceEpoch,
      ),
    );
  }

  static const Failure _noSession = AuthFailure(
    'Aucune session pour enregistrer',
  );
  static const Failure _incomplete = ValidationFailure('Contrat incomplet');

  ({String schoolId, String authorId})? _session() {
    final schoolId = _currentUser.schoolId ?? '';
    final authorId = _currentUser.uid;
    if (schoolId.isEmpty || authorId == null) return null;
    return (schoolId: schoolId, authorId: authorId);
  }

  Future<Either<Failure, Unit>> _write(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      return Left(StorageFailure('Écriture du contrat : $e'));
    }
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return const Right(unit);
  }
}
