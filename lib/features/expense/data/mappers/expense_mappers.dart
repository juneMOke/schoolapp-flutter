import 'package:school_app_flutter/core/expense/local/expense_type_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';

/// Passages entre couches, rangés à part pour garder les modèles plats.
extension ExpenseTypeLocalModelX on ExpenseTypeLocalModel {
  ExpenseType toEntity() => ExpenseType(
    id: id,
    code: code,
    label: label,
    shortLabel: shortLabel.isEmpty ? label : shortLabel,
    icon: icon,
    colorHex: color,
    softColorHex: softColor,
    defaultCurrency: defaultCurrency,
    sortOrder: sortOrder,
    active: active,
  );
}

extension ExpenseLocalModelX on ExpenseLocalModel {
  /// L'état complet à remonter — relu de la ligne rangée, pour que ce qui part
  /// sur le fil soit exactement ce que le poste affiche.
  ExpenseInputDto toInput() => ExpenseInputDto(
    id: id,
    typeId: typeId,
    title: title,
    description: description,
    amountInCents: amountInCents,
    currency: currency,
    status: status,
    paidOn: paidOn,
    expenseDate: expenseDate,
    supplier: supplier,
    fundingSource: fundingSource,
    clientUpdatedAt: clientUpdatedAt,
  );
}

extension ExpenseToDraftX on Expense {
  /// Le brouillon d'une modification : l'identifiant est gardé, le circuit
  /// reste dehors (D8).
  ExpenseDraft toDraft() => ExpenseDraft(
    id: id,
    typeId: typeId,
    title: title,
    description: description,
    amountInCents: amountInCents,
    currency: currency,
    expenseDate: expenseDate,
    supplier: supplier,
    fundingSource: fundingSource,
    recordedByName: recordedByName,
  );
}
