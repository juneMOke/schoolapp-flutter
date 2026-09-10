import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_rate_micros.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipt.dart';

/// Miroir de `TillReceiptDto` — une ligne d'encaissement, nommément.
class TillReceiptModel {
  final String paymentId;
  final DateTime paidAt;
  final String? receiptNumber;
  final String? studentName;
  final String? classroom;
  final String? collectedBy;
  final String source;
  final int amount;
  final String currency;
  final int? settledAmount;
  final String? settledCurrency;
  final int? rateMicros;

  const TillReceiptModel({
    required this.paymentId,
    required this.paidAt,
    required this.source,
    required this.amount,
    required this.currency,
    this.receiptNumber,
    this.studentName,
    this.classroom,
    this.collectedBy,
    this.settledAmount,
    this.settledCurrency,
    this.rateMicros,
  });

  /// **Le montant et sa devise lèvent ; tout le reste cède.**
  ///
  /// Une ligne de preuve sans son montant n'est pas une ligne dégradée, c'est
  /// une ligne fausse : elle s'afficherait à zéro dans une table qu'un caissier
  /// rapproche de ses billets. Les identités, elles, cèdent à `null` — un
  /// versement peut légitimement n'avoir ni élève, ni classe, ni caissier
  /// résolu, ni numéro scellé, et chacun de ces vides a sa convention
  /// d'affichage.
  ///
  /// ⚠️ **Les champs vides deviennent `null`, pas des chaînes vides.** Le tiret
  /// affiché est décidé à la lecture, sur `null` ; laisser passer une chaîne
  /// vide rendrait une cellule blanche indiscernable d'une donnée absente, et
  /// l'écran perdrait la distinction qu'il tient partout ailleurs.
  factory TillReceiptModel.fromJson(Map<String, dynamic> json) {
    return TillReceiptModel(
      paymentId: ((json['paymentId'] as String?) ?? '').trim(),
      paidAt: DateTime.parse(json['paidAt'] as String),
      // Lu tel quel, jamais recomposé : ce qui s'affiche est ce que la pièce
      // porte. Absent sur une saisie de rattrapage.
      receiptNumber: _text(json['receiptNumber']),
      studentName: _text(json['studentName']),
      classroom: _text(json['classroom']),
      collectedBy: _text(json['collectedBy']),
      source: ((json['source'] as String?) ?? '').trim().toUpperCase(),
      amount: (json['amount'] as num).toInt(),
      currency: (json['currency'] as String).trim().toUpperCase(),
      // Lu sur les imputations côté serveur, jamais dérivé du taux ici.
      settledAmount: (json['settledAmount'] as num?)?.toInt(),
      settledCurrency: _text(json['settledCurrency'])?.toUpperCase(),
      rateMicros: tillRateToMicros(json['rate']),
    );
  }

  /// `null` pour tout ce qui est absent **ou vide** — les deux disent la même
  /// chose ici, et une seule convention d'affichage doit s'ensuivre.
  static String? _text(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  TillReceipt toEntity() => TillReceipt(
    paymentId: paymentId,
    paidAt: paidAt,
    receiptNumber: receiptNumber,
    studentName: studentName,
    classroom: classroom,
    collectedBy: collectedBy,
    source: source,
    amount: amount,
    currency: currency,
    settledAmount: settledAmount,
    settledCurrency: settledCurrency,
    rateMicros: rateMicros,
  );
}
