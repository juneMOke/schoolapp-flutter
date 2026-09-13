/// Une ligne de `ref_expense_types` — un type de dépense de l'école, tel qu'il
/// dort en local.
///
/// Le type vit dans `core/` et non dans `features/expense` parce qu'il a **deux
/// rives qui ne se connaissent pas** : le pull du socle référentiel
/// (`enrollment`) le remplit, le module Dépenses le lit — et `enrollment`
/// n'importe aucun module métier. Même placement que
/// `FeeCodeSectionLocalModel`, pour la même raison.
class ExpenseTypeLocalModel {
  final String id;
  final String schoolId;
  final String code;
  final String label;
  final String shortLabel;
  final String icon;
  final String color;
  final String softColor;
  final String defaultCurrency;

  /// La **position** servie par le serveur : l'ordre de la liste fait foi.
  final int sortOrder;
  final bool active;
  final int syncedAt;

  const ExpenseTypeLocalModel({
    required this.id,
    required this.schoolId,
    required this.code,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.defaultCurrency,
    this.sortOrder = 0,
    this.active = true,
    this.syncedAt = 0,
  });

  factory ExpenseTypeLocalModel.fromMap(Map<String, Object?> map) =>
      ExpenseTypeLocalModel(
        id: (map['id'] as String?) ?? '',
        schoolId: (map['school_id'] as String?) ?? '',
        code: (map['code'] as String?) ?? '',
        label: (map['label'] as String?) ?? '',
        shortLabel: (map['short_label'] as String?) ?? '',
        icon: (map['icon'] as String?) ?? '',
        color: (map['color'] as String?) ?? '',
        softColor: (map['soft_color'] as String?) ?? '',
        defaultCurrency: (map['default_currency'] as String?) ?? '',
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        active: ((map['active'] as num?)?.toInt() ?? 1) != 0,
        syncedAt: (map['synced_at'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'school_id': schoolId,
    'code': code,
    'label': label,
    'short_label': shortLabel,
    'icon': icon,
    'color': color,
    'soft_color': softColor,
    'default_currency': defaultCurrency,
    'sort_order': sortOrder,
    'active': active ? 1 : 0,
    'synced_at': syncedAt,
  };

  /// Un type sans identifiant ne se rapproche d'aucune dépense, et un type
  /// sans libellé nommerait ses dépenses par du blanc : écartés à l'écriture.
  bool get isUsable => id.trim().isNotEmpty && label.trim().isNotEmpty;
}
