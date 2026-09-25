import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_amount_input.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';

/// L'état du formulaire, hors rendu : ce que l'agent a saisi et les règles
/// qui le font évoluer. La modale l'affiche et enveloppe chaque geste d'un
/// `setState`.
class ExpenseFormModel {
  final ExpenseFormSeed seed;
  final List<ExpenseType> types;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController amount;
  final TextEditingController supplier;
  String typeId;
  String currency;
  DateTime date;
  ExpenseFundingSource funding;

  /// L'agent a choisi la devise lui-même : un type ne la déplace plus.
  bool _currencyChosen = false;

  ExpenseFormModel(this.seed, {required this.types})
    : title = TextEditingController(text: seed.title),
      description = TextEditingController(text: seed.description),
      amount = TextEditingController(text: seed.amountText),
      supplier = TextEditingController(text: seed.supplier),
      typeId = seed.typeId,
      currency = seed.currency,
      date = seed.expenseDate,
      funding = seed.fundingSource;

  int? get cents => ExpenseAmountInput.toCents(amount.text);

  bool get hasTitle => title.text.trim().isNotEmpty;

  /// Le dollar, le franc — et la devise de la dépense si elle en porte une
  /// autre, pour qu'une modification ne la perde pas.
  List<String> get currencies =>
      {CurrencyCode.usd, CurrencyCode.cdf, currency}.toList(growable: false);

  /// Choisir un type propose sa devise habituelle, tant que rien ne l'a
  /// fixée : ni l'agent (choix explicite), ni un montant déjà saisi (il a été
  /// pensé dans une devise), ni une dépense existante (elle a la sienne).
  void selectType(String id) {
    typeId = id;
    if (seed.isEdit || _currencyChosen || amount.text.trim().isNotEmpty) {
      return;
    }
    for (final type in types) {
      if (type.id == id) currency = ExpenseFormSeed.defaultCurrencyOf(type);
    }
  }

  void chooseCurrency(String value) {
    currency = value;
    _currencyChosen = true;
  }

  /// Le brouillon, ou `null` tant qu'il manque l'intitulé, le montant ou le
  /// type.
  ExpenseDraft? draft({String? recordedByName}) {
    final cents = this.cents;
    if (!hasTitle || cents == null || typeId.isEmpty) return null;
    return ExpenseDraft(
      id: seed.id,
      typeId: typeId,
      title: title.text.trim(),
      description: description.text,
      amountInCents: cents,
      currency: currency,
      expenseDate: date,
      supplier: supplier.text,
      fundingSource: funding,
      recordedByName: recordedByName,
    );
  }

  void dispose() {
    for (final controller in [title, description, amount, supplier]) {
      controller.dispose();
    }
  }
}
