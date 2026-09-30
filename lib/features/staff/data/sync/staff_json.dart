/// Lecture tolérante des champs d'une ligne descendue : une valeur absente,
/// vide ou mal typée devient `null`, jamais une exception. C'est à l'appelant
/// de décider quels champs sont indispensables.
extension StaffJsonFields on Map<dynamic, dynamic> {
  /// Chaîne rognée, `null` si absente, vide ou d'un autre type.
  String? text(String key) {
    final value = this[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Instant ISO-8601 remis en UTC, sous une forme unique : deux écritures de
  /// forme différente se compareraient de travers.
  String? instant(String key) =>
      DateTime.tryParse(text(key) ?? '')?.toUtc().toIso8601String();

  /// Jour `YYYY-MM-DD`, sans fuseau.
  String? day(String key) {
    final value = text(key);
    if (value == null || !_day.hasMatch(value)) return null;
    return value;
  }

  int? integer(String key) {
    final value = this[key];
    return value is num ? value.toInt() : null;
  }

  /// Liste de chaînes non vides ; toute autre forme donne une liste vide.
  List<String> texts(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

final RegExp _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
