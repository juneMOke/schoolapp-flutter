import 'package:equatable/equatable.dart';

/// Nature d'une anomalie d'encaissement.
///
/// Une seule valeur en V1, et c'est délibéré : le contrat de synchro ne produit
/// qu'un signal, `overpayment`. L'enum existe pour que l'ajout d'un second motif
/// n'oblige pas à migrer la table — la colonne est déjà une chaîne libre à
/// repli explicite.
enum PaymentAnomalyKind {
  /// Trop-perçu détecté par le serveur. Le paiement est **accepté**, le reçu
  /// définitif **scellé**, et le ticket remis au parent **reste valide** — c'est
  /// la différence de fond avec le `REJETÉ` que l'ADR envisageait.
  overpayment('OVERPAYMENT'),

  /// Motif renvoyé par un serveur plus récent que cette version du client. On
  /// affiche l'anomalie plutôt que de la taire : mieux vaut une alerte au
  /// libellé générique qu'une anomalie invisible.
  unknown('UNKNOWN');

  const PaymentAnomalyKind(this.dbValue);

  final String dbValue;

  static PaymentAnomalyKind fromDbValue(String? value) =>
      switch (value?.toUpperCase()) {
        'OVERPAYMENT' => PaymentAnomalyKind.overpayment,
        _ => PaymentAnomalyKind.unknown,
      };
}

/// Une anomalie d'encaissement, à arbitrer par un opérateur.
///
/// Porte **tout ce que l'alerte doit dire** (RG-012-15 : élève, montant,
/// caissier, horodatage), recopié depuis le paiement plutôt que joint : une
/// alerte doit rester lisible même si la ligne source évolue, et l'appareil est
/// nécessaire pour savoir quelle tablette a encaissé (RG-012-16).
class PaymentAnomaly extends Equatable {
  final String id;
  final String paymentId;
  final String? studentId;
  final PaymentAnomalyKind kind;
  final int? excessInCents;
  final String? currency;
  final String? feeCode;
  final String? reason;
  final String? cashierFirstName;
  final String? cashierLastName;
  final String? deviceId;
  final int detectedAt;

  /// Époch ms de l'accusé de traitement. `null` tant que l'anomalie est ouverte.
  final int? acknowledgedAt;
  final String? acknowledgedBy;

  const PaymentAnomaly({
    required this.id,
    required this.paymentId,
    this.studentId,
    required this.kind,
    this.excessInCents,
    this.currency,
    this.feeCode,
    this.reason,
    this.cashierFirstName,
    this.cashierLastName,
    this.deviceId,
    required this.detectedAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  bool get isOpen => acknowledgedAt == null;

  String? get cashierFullName {
    final parts = [
      cashierFirstName?.trim(),
      cashierLastName?.trim(),
    ].where((p) => p != null && p.isNotEmpty).cast<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'payment_id': paymentId,
    'student_id': studentId,
    'kind': kind.dbValue,
    'excess_in_cents': excessInCents,
    'currency': currency,
    'fee_code': feeCode,
    'reason': reason,
    'cashier_first_name': cashierFirstName,
    'cashier_last_name': cashierLastName,
    'device_id': deviceId,
    'detected_at': detectedAt,
    'acknowledged_at': acknowledgedAt,
    'acknowledged_by': acknowledgedBy,
  };

  factory PaymentAnomaly.fromMap(Map<String, Object?> m) => PaymentAnomaly(
    id: m['id'] as String,
    paymentId: m['payment_id'] as String,
    studentId: m['student_id'] as String?,
    kind: PaymentAnomalyKind.fromDbValue(m['kind'] as String?),
    excessInCents: m['excess_in_cents'] as int?,
    currency: m['currency'] as String?,
    feeCode: m['fee_code'] as String?,
    reason: m['reason'] as String?,
    cashierFirstName: m['cashier_first_name'] as String?,
    cashierLastName: m['cashier_last_name'] as String?,
    deviceId: m['device_id'] as String?,
    detectedAt: (m['detected_at'] as int?) ?? 0,
    acknowledgedAt: m['acknowledged_at'] as int?,
    acknowledgedBy: m['acknowledged_by'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    paymentId,
    studentId,
    kind,
    excessInCents,
    currency,
    feeCode,
    reason,
    cashierFirstName,
    cashierLastName,
    deviceId,
    detectedAt,
    acknowledgedAt,
    acknowledgedBy,
  ];
}
