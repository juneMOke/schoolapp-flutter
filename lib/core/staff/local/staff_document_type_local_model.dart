/// Ligne de `ref_staff_document_types` : une pièce du dossier d'un agent, et
/// les contrats qui l'exigent (section `staffDocumentTypes` du socle).
///
/// Vit dans le socle et non dans le module RH : c'est la descente du
/// référentiel qui l'écrit, et elle ne doit importer aucun module métier — elle
/// reçoit une fonction qui range ces lignes (même seam que les types de
/// dépense).
class StaffDocumentTypeLocalModel {
  final String schoolId;

  /// `ID`, `DP`, `LD`, `AN`, `CT`, `CP` — gardé tel que servi : un code que ce
  /// poste ne connaît pas encore reste rangé, et s'affichera par son libellé.
  final String code;
  final String label;

  /// Exigée de tout agent, contrat posé ou non (identité, diplôme).
  final bool alwaysRequired;

  /// Les `StaffContractKind` (valeurs du fil) qui l'exigent.
  final List<String> requiredFor;

  /// Position reçue : l'ordre de la liste fait foi.
  final int sortOrder;
  final int syncedAt;

  const StaffDocumentTypeLocalModel({
    required this.schoolId,
    required this.code,
    required this.label,
    required this.alwaysRequired,
    required this.requiredFor,
    this.sortOrder = 0,
    this.syncedAt = 0,
  });

  factory StaffDocumentTypeLocalModel.fromMap(Map<String, Object?> map) =>
      StaffDocumentTypeLocalModel(
        schoolId: (map['school_id'] as String?) ?? '',
        code: (map['code'] as String?) ?? '',
        label: (map['label'] as String?) ?? '',
        alwaysRequired: ((map['always_required'] as num?)?.toInt() ?? 0) != 0,
        requiredFor: ((map['required_for'] as String?) ?? '')
            .split(',')
            .where((kind) => kind.isNotEmpty)
            .toList(growable: false),
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        syncedAt: (map['synced_at'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'school_id': schoolId,
    'code': code,
    'label': label,
    'always_required': alwaysRequired ? 1 : 0,
    'required_for': requiredFor.join(','),
    'sort_order': sortOrder,
    'synced_at': syncedAt,
  };

  bool get isUsable => code.trim().isNotEmpty && label.trim().isNotEmpty;
}
