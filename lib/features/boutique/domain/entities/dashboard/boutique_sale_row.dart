import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Un élève servi par une vente, et sa classe de l'année.
class SaleBeneficiary extends Equatable {
  final String studentId;

  /// `null` : la fiche de l'élève est introuvable (élève purgé).
  final String? fullName;

  /// `null` : l'élève n'est placé dans aucune classe de l'année.
  final String? classId;
  final String? classLabel;

  const SaleBeneficiary({
    required this.studentId,
    this.fullName,
    this.classId,
    this.classLabel,
  });

  @override
  List<Object?> get props => [studentId, fullName, classId, classLabel];
}

/// Une vente de la période, telle que `GET /boutique/sales` la rend — **une
/// ligne par vente**, même quand elle sert plusieurs élèves.
class BoutiqueSaleRow extends Equatable {
  /// L'identifiant client de la vente : la fiche se rouvre en local avec.
  final String saleId;

  /// Horodatage **métier**, ISO-8601 UTC.
  final String soldAt;

  /// `null` tant que le reçu scellé n'est pas émis.
  final String? receiptNumber;

  /// Le total **du reçu**, par devise — même sous un filtre, pour que la ligne
  /// recoupe le papier.
  final MoneyBag amounts;

  final int articleCount;

  /// Dans l'ordre des lignes de la vente ; vide pour une vente sans élève.
  final List<SaleBeneficiary> beneficiaries;

  /// `null` : vente anonyme. Ne s'affiche que sans élève.
  final String? payerName;

  const BoutiqueSaleRow({
    required this.saleId,
    required this.soldAt,
    required this.amounts,
    required this.articleCount,
    this.receiptNumber,
    this.beneficiaries = const [],
    this.payerName,
  });

  @override
  List<Object?> get props => [
    saleId,
    soldAt,
    receiptNumber,
    amounts,
    articleCount,
    beneficiaries,
    payerName,
  ];
}
