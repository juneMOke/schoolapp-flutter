/// DTOs du delta de synchronisation éditique (`GET /api/v1/sync/editique-documents`).
///
/// **Aucun octet ne transite ici**, et ce n'est pas une optimisation : une page
/// de 100 pièces représenterait une dizaine de mégaoctets de base64 sur des
/// liaisons qui n'en veulent pas. La tablette apprend ce qui existe, puis tire
/// les octets un par un, à la demande.
library;

import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

/// Une pièce scellée telle que le serveur la décrit — métadonnées seules.
class PulledEditiqueDocument {
  final String id;
  final String docType;
  final String documentNumber;
  final String? studentId;
  final String? academicYearId;
  final int? emittedAtMs;
  final int sizeBytes;

  /// Empreinte que le **serveur** a scellée. Conservée pour vérifier un
  /// téléchargement de bout en bout ; ce n'est PAS l'empreinte à écrire dans
  /// l'index — celle-ci n'y est posée que lorsque les octets sont réellement
  /// détenus.
  final String? contentSha256;

  final String? supersedesNumber;

  /// Époch ms du retrait de la pièce, `null` tant qu'elle est en vigueur.
  ///
  /// Une annulation est un `UPDATE` côté serveur : le déclencheur de visibilité
  /// relève `serverUpdatedAt`, qui EST le curseur du delta, donc la ligne
  /// redescend d'elle-même. Sans ce champ elle redescendrait **identique**, et
  /// la tablette continuerait de proposer une pièce retirée.
  final int? cancelledAtMs;

  /// Motif du retrait. Texte libre d'un agent, descendu tel quel — il ne se
  /// traduit ni ne se reformule.
  final String? cancellationReason;

  const PulledEditiqueDocument({
    required this.id,
    required this.docType,
    required this.documentNumber,
    this.studentId,
    this.academicYearId,
    this.emittedAtMs,
    required this.sizeBytes,
    this.contentSha256,
    this.supersedesNumber,
    this.cancelledAtMs,
    this.cancellationReason,
  });

  factory PulledEditiqueDocument.fromJson(Map<String, dynamic> j) =>
      PulledEditiqueDocument(
        id: j['id'] as String,
        docType: j['docType'] as String,
        documentNumber: (j['documentNumber'] as String?) ?? '',
        studentId: j['studentId'] as String?,
        academicYearId: j['academicYearId'] as String?,
        emittedAtMs: _isoToMs(j['emittedAt'] as String?),
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        contentSha256: j['contentSha256'] as String?,
        supersedesNumber: j['supersedesNumber'] as String?,
        cancelledAtMs: _isoToMs(j['cancelledAt'] as String?),
        cancellationReason: j['cancellationReason'] as String?,
      );

  /// Entrée d'index **sans octets** : `contentSha256` reste nul, c'est ce qui
  /// dit que la pièce est connue mais pas détenue.
  ///
  /// L'identifiant local est laissé vide : il appartient au cache, qui garde
  /// celui d'une ligne déjà connue — c'est lui qui nomme le fichier chiffré —
  /// et en attribue un aux pièces nouvelles.
  EditiqueCacheEntry toCacheEntry({
    required String schoolId,
    required int nowMs,
  }) => EditiqueCacheEntry(
    id: '',
    documentId: id,
    documentNumber: documentNumber,
    docType: docType,
    studentId: studentId,
    academicYearId: academicYearId,
    schoolId: schoolId,
    sizeBytes: sizeBytes,
    emittedAt: emittedAtMs,
    // Le retrait, lui, se propage jusqu'à l'index : c'est la seule voie par
    // laquelle la tablette peut l'apprendre. Le jeter ici le rendrait invisible
    // partout en aval, sans qu'aucun test ne rougisse.
    cancelledAt: cancelledAtMs,
    cancellationReason: cancellationReason,
    createdAt: nowMs,
    lastAccessedAt: nowMs,
  );
}

/// Page keyset du delta éditique.
class EditiqueDocumentPageDto implements KeysetPageDto<PulledEditiqueDocument> {
  @override
  final List<PulledEditiqueDocument> items;

  @override
  final KeysetPageEnvelope page;

  const EditiqueDocumentPageDto({required this.items, required this.page});

  factory EditiqueDocumentPageDto.fromJson(Map<String, dynamic> j) =>
      EditiqueDocumentPageDto(
        items: _lenientList(j['items'], PulledEditiqueDocument.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée plutôt que de figer le curseur. La pièce
/// écartée reviendra au prochain delta une fois le serveur corrigé — alors
/// qu'une page empoisonnée bloquerait la ressource pour toujours.
List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final entry in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(entry as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée : le curseur avance, la ressource ne fige pas.
    }
  }
  return out;
}

int? _isoToMs(String? iso) {
  if (iso == null) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return null;
  // Le wire est UTC. Un ISO **naïf** (sans `Z` ni offset) serait interprété en
  // heure locale, ce qui décalerait l'instant du fuseau de l'appareil.
  final utc = parsed.isUtc
      ? parsed
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.millisecondsSinceEpoch;
}
