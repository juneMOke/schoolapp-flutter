/// Une pièce du dossier d'un agent et les contrats qui l'exigent
/// (`StaffDocumentTypeDto` côté serveur, section `staffDocumentTypes` du
/// socle).
///
/// Lue **élément par élément, sans lever**, comme les types de dépense : une
/// pièce illisible ne doit pas faire tomber le socle, qui porte l'année et les
/// niveaux. Un élément sans code ou sans libellé est écarté ; un statut de
/// contrat inconnu est gardé tel quel — le module RH l'ignorera.
class RefStaffDocumentTypeDto {
  final String code;
  final String label;
  final bool alwaysRequired;
  final List<String> requiredFor;

  const RefStaffDocumentTypeDto({
    required this.code,
    required this.label,
    required this.alwaysRequired,
    required this.requiredFor,
  });

  static RefStaffDocumentTypeDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    String text(String key) {
      final value = raw[key];
      return value is String ? value.trim() : '';
    }

    final code = text('code').toUpperCase();
    final label = text('label');
    if (code.isEmpty || label.isEmpty) return null;
    final always = raw['alwaysRequired'];
    final kinds = raw['requiredFor'];
    return RefStaffDocumentTypeDto(
      code: code,
      label: label,
      alwaysRequired: always is bool && always,
      requiredFor: [
        if (kinds is List)
          for (final kind in kinds)
            if (kind is String && kind.trim().isNotEmpty)
              kind.trim().toUpperCase(),
      ],
    );
  }

  /// La section entière, ou `null` quand elle n'est pas communiquée : clé
  /// absente, valeur nulle, liste vide ou rien de lisible dedans. Dans ces cas
  /// le cache reste tel quel.
  static List<RefStaffDocumentTypeDto>? listOrNull(Object? raw) {
    if (raw is! List) return null;
    final types = [for (final item in raw) ?tryParse(item)];
    return types.isEmpty ? null : types;
  }
}
