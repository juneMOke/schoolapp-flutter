/// Une ligne de `ref_fee_code_sections` — le titre que l'école donne à une
/// nature de frais, tel qu'il dort en local.
///
/// **Cache d'affichage** : écrit par le pull (et par l'écran de nommage, juste
/// après avoir écrit côté serveur), lu par les écrans qui nomment un frais.
/// Rien ne s'écrit jamais d'ici vers le serveur.
///
/// Le type vit dans `core/` et non dans une feature parce qu'il a **deux rives
/// qui ne se connaissent pas** : Configuration le remplit, Finance le lit, et
/// aucune des deux n'importe l'autre aujourd'hui. Même placement que
/// `ExchangeRateLocalModel`, pour la même raison.
class FeeCodeSectionLocalModel {
  final String schoolId;

  /// La clé — `TUITION`. Identique d'une école à l'autre ; c'est elle, et jamais
  /// le titre, qui part sur le fil.
  final String code;

  /// Le titre écrit par la direction, ou la proposition du serveur tant qu'elle
  /// ne l'a pas réécrite.
  final String label;

  /// La section est-elle encore proposée à la saisie ?
  ///
  /// ⚠️ **Stocké, et ne filtre RIEN à la lecture.** Masquer dit « ne me la
  /// propose plus », jamais « ne sais plus la nommer » : une créance posée sur
  /// une nature depuis masquée doit garder son titre. Le champ est conservé
  /// pour le jour où un sélecteur lira cette table — il n'en existe aucun.
  final bool active;

  /// Rang d'affichage servi par le serveur. Conservé pour la même raison que
  /// [active] : rien ne le lit ici, et le perdre obligerait à re-tirer la route
  /// pour le retrouver.
  final int sortOrder;

  final int syncedAt;

  const FeeCodeSectionLocalModel({
    required this.schoolId,
    required this.code,
    required this.label,
    this.active = true,
    this.sortOrder = 0,
    this.syncedAt = 0,
  });

  factory FeeCodeSectionLocalModel.fromMap(Map<String, Object?> map) =>
      FeeCodeSectionLocalModel(
        schoolId: (map['school_id'] as String?) ?? '',
        code: (map['code'] as String?) ?? '',
        label: (map['label'] as String?) ?? '',
        active: ((map['active'] as num?)?.toInt() ?? 1) != 0,
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        syncedAt: (map['synced_at'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'school_id': schoolId,
    'code': code,
    'label': label,
    'active': active ? 1 : 0,
    'sort_order': sortOrder,
    'synced_at': syncedAt,
  };

  /// Vrai quand la ligne peut nommer quelque chose.
  ///
  /// Un code vide ne se rapproche d'aucune créance, et un titre vide
  /// remplacerait la nature localisée par du blanc — strictement pire que le
  /// repli. Les deux sont écartés à l'écriture plutôt qu'à la lecture : une
  /// ligne inutilisable n'a aucune raison d'occuper la table.
  bool get isUsable => code.trim().isNotEmpty && label.trim().isNotEmpty;
}
