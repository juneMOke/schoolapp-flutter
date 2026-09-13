import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Ce que le formulaire soumet — création, modification ou duplication.
///
/// Trois cas, un seul objet, distingués par la présence d'un [id] : une
/// duplication est une **création** (id vidé, date du jour, non payée).
class ExpenseDraft extends Equatable {
  /// `null` = création (duplication comprise) ; l'identifiant est alors
  /// fabriqué par le poste, clé d'idempotence de la remontée.
  final String? id;
  final String typeId;
  final String title;
  final String? description;
  final int amountInCents;
  final String currency;
  final ExpenseStatus status;
  final DateTime expenseDate;
  final String? supplier;
  final ExpenseFundingSource fundingSource;

  /// Nom de l'agent connecté, affiché tant que le serveur n'a pas renvoyé le
  /// sien — jamais saisi.
  final String? recordedByName;

  const ExpenseDraft({
    this.id,
    required this.typeId,
    required this.title,
    this.description,
    required this.amountInCents,
    required this.currency,
    required this.status,
    required this.expenseDate,
    this.supplier,
    this.fundingSource = ExpenseFundingSource.cash,
    this.recordedByName,
  });

  bool get isCreation => id == null;

  @override
  List<Object?> get props => [
    id,
    typeId,
    title,
    description,
    amountInCents,
    currency,
    status,
    expenseDate,
    supplier,
    fundingSource,
    recordedByName,
  ];
}
