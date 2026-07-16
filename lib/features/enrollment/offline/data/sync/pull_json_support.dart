/// Helper de désérialisation partagé par les modèles de pull : projette une
/// liste JSON brute (ou `null`) en `List<T>` via le `fromJson` fourni.
List<T> pullList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) =>
    (raw as List<dynamic>? ?? const [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
