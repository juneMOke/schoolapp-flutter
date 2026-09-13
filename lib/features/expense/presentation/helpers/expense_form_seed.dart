import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_amount_input.dart';

/// Les trois cas du formulaire (spec §7), distingués par la présence d'un id.
enum ExpenseFormMode { create, edit, duplicate }

/// Ce que le formulaire affiche à l'ouverture. Il ne demande jamais ce qu'il
/// peut déduire : la devise suit le type, la date est celle du jour, l'agent
/// est l'utilisateur connecté.
class ExpenseFormSeed {
  final ExpenseFormMode mode;
  final String? id;
  final String? number;
  final String typeId;
  final String title;
  final String description;
  final String amountText;
  final String currency;
  final ExpenseStatus status;
  final DateTime expenseDate;
  final String supplier;
  final ExpenseFundingSource fundingSource;

  const ExpenseFormSeed._({
    required this.mode,
    this.id,
    this.number,
    required this.typeId,
    required this.title,
    required this.description,
    required this.amountText,
    required this.currency,
    required this.status,
    required this.expenseDate,
    required this.supplier,
    required this.fundingSource,
  });

  /// Création : le premier type offert — l'ordre du référentiel de l'école,
  /// jamais un code écrit en dur — ; sa devise habituelle ; payée ;
  /// aujourd'hui.
  factory ExpenseFormSeed.blank({
    required List<ExpenseType> types,
    required DateTime today,
  }) {
    final type = types.isEmpty ? null : types.first;
    return ExpenseFormSeed._(
      mode: ExpenseFormMode.create,
      typeId: type?.id ?? '',
      title: '',
      description: '',
      amountText: '',
      currency: defaultCurrencyOf(type),
      status: ExpenseStatus.paid,
      expenseDate: ExpenseDay.of(today),
      supplier: '',
      fundingSource: ExpenseFundingSource.cash,
    );
  }

  factory ExpenseFormSeed.edit(Expense expense) => ExpenseFormSeed._(
    mode: ExpenseFormMode.edit,
    id: expense.id,
    number: expense.number,
    typeId: expense.typeId,
    title: expense.title,
    description: expense.description ?? '',
    amountText: ExpenseAmountInput.fromCents(expense.amountInCents),
    currency: expense.currency,
    status: expense.status,
    expenseDate: expense.expenseDate,
    supplier: expense.supplier ?? '',
    fundingSource: expense.fundingSource,
  );

  /// Duplication : le report d'une charge récurrente — id vidé, **date du
  /// jour** (hériter de la date reporterait la dépense au mois précédent) et
  /// **non payée** (hériter de « payée » enregistrerait un paiement qui n'a
  /// pas eu lieu).
  factory ExpenseFormSeed.duplicate(
    Expense expense, {
    required DateTime today,
  }) => ExpenseFormSeed._(
    mode: ExpenseFormMode.duplicate,
    typeId: expense.typeId,
    title: expense.title,
    description: expense.description ?? '',
    amountText: ExpenseAmountInput.fromCents(expense.amountInCents),
    currency: expense.currency,
    status: ExpenseStatus.unpaid,
    expenseDate: ExpenseDay.of(today),
    supplier: expense.supplier ?? '',
    fundingSource: expense.fundingSource,
  );

  bool get isEdit => mode == ExpenseFormMode.edit;

  /// La devise que le formulaire propose pour un type — un défaut, jamais une
  /// contrainte ; le dollar quand le type n'en dit rien.
  static String defaultCurrencyOf(ExpenseType? type) {
    final value = CurrencyCode.normalize(type?.defaultCurrency ?? '');
    return value.isEmpty ? CurrencyCode.usd : value;
  }
}
