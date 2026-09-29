import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/person_name_comparator.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_mapping.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_member_input_mapper.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_pull_repository_impl.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_push_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_timeline_merge.dart';

/// Le fichier du personnel lu sur la tablette, modèles convertis en entités
/// ici et nulle part ailleurs (règle n°3).
class StaffRepositoryImpl implements StaffRepository {
  final StaffMemberDao _members;
  final StaffContractDao _contracts;
  final StaffMemberWriteDao _writer;
  final StaffDocumentDao _documents;
  final StaffDocumentTypeDao _types;
  final SyncMetaDao _syncMeta;
  final CurrentUserContext _currentUser;

  /// Relance le flush après une écriture ; `null` dans les tests qui n'en
  /// ont pas besoin.
  final SyncEngine? _syncEngine;
  final DateTime Function() _now;

  const StaffRepositoryImpl({
    required StaffMemberDao members,
    required StaffContractDao contracts,
    required StaffMemberWriteDao writer,
    required StaffDocumentDao documents,
    required StaffDocumentTypeDao types,
    required SyncMetaDao syncMeta,
    required CurrentUserContext currentUser,
    SyncEngine? syncEngine,
    DateTime Function() now = DateTime.now,
  }) : _members = members,
       _contracts = contracts,
       _writer = writer,
       _documents = documents,
       _types = types,
       _syncMeta = syncMeta,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  /// Nom → Post-nom → Prénom, accents et casse repliés : `COLLATE NOCASE`
  /// rangerait « Émile » après « Zacharie ».
  static final Comparator<StaffMember> _byName = PersonNameComparator.by(
    lastName: (m) => m.lastName,
    surname: (m) => m.middleName,
    firstName: (m) => m.firstName,
    id: (m) => m.id,
  );

  @override
  Future<Either<Failure, StaffFileSnapshot>> loadFile() async {
    final schoolId = _currentUser.schoolId ?? '';
    if (schoolId.isEmpty) return const Right(StaffFileSnapshot.empty);
    try {
      final local = <String, List<StaffContract>>{};
      for (final row in await _contracts.forSchool(schoolId)) {
        final contract = row.toEntity();
        local.putIfAbsent(contract.staffMemberId, () => []).add(contract);
      }
      final members = [
        for (final row in await _members.listForSchool(schoolId))
          if (row.toEntity() case final member)
            _withLocalContracts(member, local[member.id] ?? const []),
      ]..sort(_byName);
      final documents = <String, List<StaffDocument>>{};
      for (final row in await _documents.listForSchool(schoolId)) {
        final document = row.toEntity();
        documents.putIfAbsent(document.staffMemberId, () => []).add(document);
      }
      final syncedAt = await _syncMeta.getSyncedAt(
        staffCursorKey(kStaffMembersResource, schoolId),
      );
      return Right(
        StaffFileSnapshot(
          members: members,
          documentsByMember: documents,
          documentTypes: [
            for (final type in await _types.forSchool(schoolId))
              type.toEntity(),
          ],
          hasEverSynced: syncedAt != null,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Lecture du fichier du personnel : $e'));
    }
  }

  @override
  Future<Either<Failure, StaffMember>> findMember(String staffMemberId) async {
    try {
      final row = await _members.find(staffMemberId);
      if (row == null) {
        return const Left(NotFoundFailure('Agent inconnu sur la tablette'));
      }
      final local = [
        for (final contract in await _contracts.forMember(staffMemberId))
          contract.toEntity(),
      ];
      return Right(_withLocalContracts(row.toEntity(), local));
    } catch (e) {
      return Left(StorageFailure('Lecture de la fiche : $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveMember(StaffMemberDraft draft) async {
    final schoolId = _currentUser.schoolId ?? '';
    final authorId = _currentUser.uid;
    if (schoolId.isEmpty || authorId == null) {
      return const Left(AuthFailure('Aucune session pour enregistrer'));
    }
    final now = _now();
    final input = StaffMemberInputMapper.of(
      draft,
      clientUpdatedAt: now.toUtc().toIso8601String(),
    );
    if (input == null) {
      return const Left(ValidationFailure('Fiche incomplète'));
    }
    try {
      await _writer.save(
        request: StaffMemberSyncRequestDto(
          staffMember: input,
          authorId: authorId,
        ),
        schoolId: schoolId,
        nowMs: now.millisecondsSinceEpoch,
      );
    } catch (e) {
      return Left(StorageFailure('Écriture de la fiche : $e'));
    }
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return const Right(unit);
  }

  /// La frise de la fiche complétée par les périodes que le poste connaît
  /// mieux qu'elle — sans quoi un contrat posé hors ligne n'apparaîtrait
  /// nulle part.
  static StaffMember _withLocalContracts(
    StaffMember member,
    List<StaffContract> local,
  ) => local.isEmpty
      ? member
      : member.withContracts(StaffTimelineMerge.merge(member.contracts, local));
}
