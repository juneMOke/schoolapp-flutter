import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Entrée d'index de cache éditique par défaut, à surcharger champ par champ.
///
/// Les valeurs par défaut décrivent le cas courant : un reçu archivé, connu à
/// la fois par son identifiant serveur et par son numéro. Attention aux deux
/// identités uniques — deux entrées d'un même test doivent différer **et** par
/// `documentId` **et** par `documentNumber`, sinon la seconde met à jour la
/// première au lieu de s'ajouter (comportement voulu de `upsert`).
EditiqueCacheEntry cacheEntry({
  String id = 'c-1',
  String? documentId = 'doc-1',
  String? documentNumber = 'ETL-RC-2526-000001',
  String docType = 'RC',
  String? studentId = 's-1',
  String? academicYearId = 'y-1',
  String schoolId = 'school-1',
  String ownerUid = 'u-1',
  int sizeBytes = 1024,
  String contentSha256 = 'abc',
  int? emittedAt = 1000,
  int createdAt = 2000,
  int lastAccessedAt = 3000,
}) => EditiqueCacheEntry(
  id: id,
  documentId: documentId,
  documentNumber: documentNumber,
  docType: docType,
  studentId: studentId,
  academicYearId: academicYearId,
  schoolId: schoolId,
  ownerUid: ownerUid,
  sizeBytes: sizeBytes,
  contentSha256: contentSha256,
  emittedAt: emittedAt,
  createdAt: createdAt,
  lastAccessedAt: lastAccessedAt,
);
