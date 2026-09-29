import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/person_name_comparator.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/staff/local/staff_document_type_local_model.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_pull_repository_impl.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';

/// Le fichier du personnel lu sur la tablette, modèles convertis en entités
/// ici et nulle part ailleurs (règle n°3).
class StaffRepositoryImpl implements StaffRepository {
  final StaffMemberDao _members;
  final StaffDocumentDao _documents;
  final StaffDocumentTypeDao _types;
  final SyncMetaDao _syncMeta;
  final CurrentUserContext _currentUser;

  const StaffRepositoryImpl({
    required StaffMemberDao members,
    required StaffDocumentDao documents,
    required StaffDocumentTypeDao types,
    required SyncMetaDao syncMeta,
    required CurrentUserContext currentUser,
  }) : _members = members,
       _documents = documents,
       _types = types,
       _syncMeta = syncMeta,
       _currentUser = currentUser;

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
      final members = [
        for (final row in await _members.listForSchool(schoolId))
          row.toEntity(),
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
            for (final type in await _types.forSchool(schoolId)) _typeOf(type),
          ],
          hasEverSynced: syncedAt != null,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Lecture du fichier du personnel : $e'));
    }
  }

  static StaffDocumentType _typeOf(StaffDocumentTypeLocalModel model) =>
      StaffDocumentType(
        code: StaffDocumentCode.fromWire(model.code),
        rawCode: model.code,
        label: model.label,
        alwaysRequired: model.alwaysRequired,
        requiredFor: {
          for (final kind in model.requiredFor)
            ?StaffContractKind.fromWire(kind),
        },
      );
}
