import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_article.dart';

/// Un élève qui a reçu quelque chose de la boutique sur la fenêtre.
///
/// **Une ligne par élève, pas par vente** : un parent qui achète pour trois
/// enfants en produit trois ; un élève servi deux fois n'en produit qu'une, qui
/// cumule.
class BoutiqueBeneficiary extends Equatable {
  final String studentId;

  /// NOM Post-nom Prénom, composé par le serveur — jamais recomposé ici.
  final String fullName;

  /// L'affectation de l'élève dans l'année, `null` s'il n'est pas encore placé.
  final String? classId;
  final String? classLabel;

  final DateTime lastPurchaseAt;

  /// Σ des lignes **dont il est bénéficiaire** — jamais le total du reçu : le
  /// payeur a pu acheter pour d'autres.
  final MoneyBag amounts;

  final List<BeneficiaryArticle> articles;

  const BoutiqueBeneficiary({
    required this.studentId,
    required this.fullName,
    required this.lastPurchaseAt,
    required this.amounts,
    this.classId,
    this.classLabel,
    this.articles = const [],
  });

  @override
  List<Object?> get props => [
    studentId,
    fullName,
    classId,
    classLabel,
    lastPurchaseAt,
    amounts,
    articles,
  ];
}
