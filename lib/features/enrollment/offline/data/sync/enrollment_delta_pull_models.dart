import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/pull_json_support.dart';

// Pull delta descendant MAIGRE des inscriptions — `GET /api/v1/sync/enrollments`
// (réconciliation multi-tablettes, PAS l'affichage — ADR-003).

/// Page delta keyset des inscriptions (enveloppe [KeysetPageEnvelope] :
/// `nextCursor`/`nextWatermark`/`hasMore` — ADR-008/009).
class EnrollmentDeltaPageDto implements KeysetPageDto<EnrollmentDeltaDto> {
  @override
  final List<EnrollmentDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const EnrollmentDeltaPageDto({required this.items, required this.page});

  factory EnrollmentDeltaPageDto.fromJson(Map<String, dynamic> j) =>
      EnrollmentDeltaPageDto(
        items: pullList(j['items'], EnrollmentDeltaDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}

/// Ligne delta d'une inscription. `updatedAt` = heure métier (LWW) ;
/// `serverUpdatedAt` = temps de visibilité serveur, **miroir de contrat** : c'est
/// le jeton opaque de l'enveloppe ([KeysetPageEnvelope]) qui pilote l'avance du
/// curseur, pas ce champ, purement informatif ici (ADR-008).
/// `academicYearId` est nullable : absent des `required` du contrat.
class EnrollmentDeltaDto {
  final String id;
  final String studentId;
  final String? matriculationNumber;
  final String? schoolLevelId;
  final String? academicYearId;
  final String status;
  final String updatedAt; // ISO-8601 (LWW)
  final String serverUpdatedAt; // ISO-8601 (curseur)

  const EnrollmentDeltaDto({
    required this.id,
    required this.studentId,
    this.matriculationNumber,
    this.schoolLevelId,
    this.academicYearId,
    required this.status,
    required this.updatedAt,
    required this.serverUpdatedAt,
  });

  factory EnrollmentDeltaDto.fromJson(Map<String, dynamic> j) =>
      EnrollmentDeltaDto(
        id: j['id'] as String,
        studentId: j['studentId'] as String,
        matriculationNumber: j['matriculationNumber'] as String?,
        schoolLevelId: j['schoolLevelId'] as String?,
        academicYearId: j['academicYearId'] as String?,
        status: j['status'] as String,
        updatedAt: j['updatedAt'] as String,
        serverUpdatedAt: j['serverUpdatedAt'] as String,
      );
}
