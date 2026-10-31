import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';

/// Une rubrique dans la modale : son champ, et ce qu'elle portait à l'ouverture.
///
/// Le champ s'ouvre sur **ce qui compte** — la valeur du serveur quand la saisie
/// a été refusée, le défaut sans saisie, vide pour une autre devise. Un montant
/// refusé ne se remplit jamais : il repartirait sans geste de l'économe.
class PayrollCustomField {
  final PayrollDeductionType type;
  final PayrollDeductionEntry? entry;
  final String currency;
  final TextEditingController controller;

  /// Le montant de la ligne à l'ouverture, dans sa devise : laissé tel quel,
  /// il n'écrit rien, et le défaut reste libre de suivre le catalogue.
  final int _openedInCents;

  /// Le texte à l'ouverture : retaper le défaut est une saisie, l'ignorer non.
  final String _openedText;

  /// L'économe a demandé la mise à 0 d'une rubrique verrouillée.
  bool _cleared = false;

  PayrollCustomField._(
    this.type,
    this.entry,
    this.currency,
    this.controller,
    this._openedInCents,
    this._openedText,
  );

  factory PayrollCustomField.of(
    PayrollDeductionType type,
    PayrollDeductionEntry? entry,
    String currency,
  ) {
    final counted = entry?.counted;
    final defaulted =
        counted == null &&
        !type.archived &&
        type.defaultCounts &&
        _concerns(type, currency);
    final amount = defaulted
        ? type.defaultAmountInCents
        : counted != null && _sameCurrency(counted, currency)
        ? counted.amountInCents
        : 0;
    // Un 0 saisi contre un défaut se montre : vide, il se lirait « rien ».
    final zeroed =
        counted != null &&
        counted.amountInCents == 0 &&
        type.defaultAmountInCents > 0;
    final text = amount > 0
        ? MoneyFormat.amountOnly(Money(amount, currency))
        : zeroed
        ? '0'
        : '';
    return PayrollCustomField._(
      type,
      entry,
      currency,
      TextEditingController(text: text),
      amount,
      text,
    );
  }

  /// Une rubrique concerne la ligne de sa devise. Sans devise, elle vient d'un
  /// serveur antérieur au contrat : le champ reste ouvert, et le refus tranchera.
  static bool _concerns(PayrollDeductionType type, String currency) =>
      type.currency.isEmpty || type.appliesTo(currency);

  /// La rubrique a-t-elle sa place dans la modale de cette ligne ?
  static bool shown(
    PayrollDeductionType type,
    PayrollDeductionEntry? entry,
    String currency,
  ) =>
      (!type.archived && _concerns(type, currency)) ||
      (entry?.counted?.amountInCents ?? 0) > 0;

  /// Lit un montant où 0 est permis : `null` si ce n'en est pas un.
  static int? centsOf(String text) =>
      _zero.hasMatch(text) ? 0 : AmountInput.toCents(text);

  static bool _sameCurrency(PayrollDeductionEntry entry, String currency) =>
      CurrencyCode.normalize(entry.currency) ==
      CurrencyCode.normalize(currency);

  /// Ce qui compte aujourd'hui pour cette rubrique, s'il y a quelque chose.
  PayrollDeductionEntry? get _counted {
    final counted = entry?.counted;
    return counted != null && counted.amountInCents > 0 ? counted : null;
  }

  /// La valeur qui compte est dans une autre devise que la ligne.
  bool get foreign {
    final counted = _counted;
    return counted != null && !_sameCurrency(counted, currency);
  }

  /// Le montant en autre devise, dans sa propre devise.
  PayrollDeductionEntry? get foreignEntry => foreign ? _counted : null;

  bool get refused => entry?.syncState == RecordSyncState.failed;

  /// Archivée, ou dans une autre devise : seule la mise à 0 est permise.
  bool get locked => type.archived || !_concerns(type, currency);

  /// Le défaut que le champ remplace, à rappeler sous la saisie.
  int? get defaultInCents =>
      !locked && type.defaultCounts && type.defaultAmountInCents > 0
      ? type.defaultAmountInCents
      : null;

  /// La mise à 0 d'une rubrique verrouillée a encore quelque chose à faire.
  bool get clearable => !_cleared && (foreign || amountInCents > 0);

  void clear() {
    _cleared = true;
    controller.clear();
  }

  /// `AmountInput` ne connaît que les montants positifs ; ici, 0 retire la
  /// retenue.
  static final RegExp _zero = RegExp(r'^\s*0*([.,]0*)?\s*$');

  /// Le texte saisi n'est pas un montant.
  bool get invalid => centsOf(controller.text) == null;

  int get amountInCents => centsOf(controller.text) ?? 0;

  bool get _touched => _cleared || controller.text.trim().isNotEmpty;

  /// L'économe a retapé le défaut d'un agent sans saisie : il le fige pour cet
  /// agent, même si le catalogue change ensuite.
  bool get _defaultRetyped =>
      entry?.counted == null &&
      defaultInCents != null &&
      controller.text.trim() != _openedText;

  /// La saisie à écrire, ou `null` si rien n'a changé. Dans une autre devise,
  /// un champ laissé vide ne dit rien ; un 0 tapé efface.
  PayrollDeductionEntry? changed(String staffMemberId) {
    if (invalid) return null;
    if (amountInCents == _openedInCents &&
        !(foreign && _touched) &&
        !_defaultRetyped) {
      return null;
    }
    return PayrollDeductionEntry(
      staffMemberId: staffMemberId,
      deductionTypeId: type.id,
      amountInCents: amountInCents,
      currency: currency,
    );
  }

  /// Le montant tel qu'il compterait, pour l'aperçu. Toujours rendu, 0 compris :
  /// sans saisie, le moteur reprendrait le défaut que le champ vient d'écarter.
  PayrollDeductionEntry preview(String staffMemberId) => PayrollDeductionEntry(
    staffMemberId: staffMemberId,
    deductionTypeId: type.id,
    amountInCents: amountInCents,
    currency: currency,
  );
}
