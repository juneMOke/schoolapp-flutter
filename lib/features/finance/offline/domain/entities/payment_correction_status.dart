/// Où en est une correction de versement (annulation, ou annulation et
/// remplacement), persistée dans `payment_corrections.status`.
///
/// Un état à part, et pas `SyncState` : une correction refusée n'est pas « à
/// corriger ». Le serveur n'a rien changé, l'origine reprend cours, et la ligne
/// ne fait plus que garder la trace du refus.
enum PaymentCorrectionStatus {
  /// Appliquée sur la tablette, en attente de l'accusé du serveur. L'origine
  /// sort des soldes dès maintenant.
  pending('PENDING'),

  /// Acquittée : le serveur a annulé l'origine (et enregistré le remplaçant).
  /// Son annulation est désormais dans `payments.cancelled_at`.
  applied('APPLIED'),

  /// Refusée pour de bon (403, versement déjà corrigé, remplaçant invalide).
  /// Rien n'a changé côté serveur : l'origine compte de nouveau.
  rejected('REJECTED'),

  /// L'origine n'a jamais été acceptée par le serveur : la correction ne
  /// part pas, elle vaut sur la tablette seule et l'origine est abandonnée.
  localOnly('LOCAL_ONLY');

  const PaymentCorrectionStatus(this.dbValue);

  final String dbValue;

  /// Une valeur inconnue retombe sur [pending] : dans le doute, l'origine
  /// reste hors des soldes plutôt que d'y revenir sans qu'on l'ait décidé.
  static PaymentCorrectionStatus fromDbValue(String? value) =>
      PaymentCorrectionStatus.values.firstWhere(
        (s) => s.dbValue == value?.toUpperCase(),
        orElse: () => PaymentCorrectionStatus.pending,
      );

  /// La correction retire son versement d'origine des soldes.
  bool get removesOrigin => this != PaymentCorrectionStatus.rejected;
}
