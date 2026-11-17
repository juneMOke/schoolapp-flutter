import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_lines.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_sheet.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_primitives.dart';

/// L'argent sur un ticket de caisse : le montant reçu, ses taux, et la mise en
/// forme des montants. Partagé par la perception et la vente boutique, pour que
/// deux pièces de la même caisse écrivent leurs chiffres de la même façon.
abstract final class TicketMoneySections {
  /// « Montant reçu » (gras, une ligne par devise), puis le taux de chaque
  /// règlement converti.
  ///
  /// Le taux s'imprime **seulement** quand les deux unités divergent : c'est le
  /// chiffre que le parent conteste au guichet, et le laisser déduire par
  /// division lui ferait lire un taux dérivé de l'arrondi. Un « 1,00 » sur un
  /// règlement ordinaire ferait chercher ce qui a été converti.
  static void amountReceived(
    TicketSheet sheet, {
    required String amountReceivedLabel,
    required String rateLabel,
    required List<TicketTenderLine> tenders,
  }) {
    final width = sheet.width;
    final received = MoneyBag.sumBy(
      tenders,
      (tender) => Money.parse(tender.amountInCents, tender.currency),
    );
    sheet.emphasised(
      () => addMoneyBag(sheet.lines, amountReceivedLabel, received, width),
    );
    for (final tender in tenders) {
      if (tender.isIdentity) continue;
      TicketTextPrimitives.addPair(
        sheet.lines,
        rateLabel,
        formatRate(tender, width),
        width,
      );
    }
  }

  /// Un libellé, puis **une ligne par devise** ; le libellé ne se répète pas.
  ///
  /// Les devises ne s'additionnent jamais : un total qui mêlerait dollars et
  /// francs imprimerait un chiffre qui n'est l'argent de personne.
  static void addMoneyBag(
    List<String> lines,
    String label,
    MoneyBag bag,
    int width,
  ) {
    if (bag.isEmpty) return;
    var first = true;
    for (final amount in bag.entries) {
      TicketTextPrimitives.addPair(
        lines,
        first ? label : '',
        formatAmount(amount.amountInCents, amount.currency),
        width,
      );
      first = false;
    }
  }

  /// Montant en centimes → « 1 234 FC », « 425,00 $ ».
  ///
  /// Les décimales se décident sur la **devise** (`MoneyFormat`). Formateur
  /// pur, espace de groupement ordinaire : une thermique ne rend pas
  /// l'insécable.
  static String formatAmount(int cents, String currency) => MoneyFormat.format(
    Money.parse(cents, currency),
    space: MoneyFormat.thermalSpace,
  );

  /// Le taux, tel qu'il s'imprime : « 1 666,67 FC / $ ».
  ///
  /// Deux décimales, celles-là mêmes qui sont stockées. Sur un ticket étroit,
  /// la forme « FC / $ » cède à la seule devise reçue : c'est le nombre qui
  /// compte.
  static String formatRate(TicketTenderLine tender, int width) {
    final value = tender.rate.formatted(space: MoneyFormat.thermalSpace);
    final quote = MoneyFormat.symbolOf(tender.currency);
    if (width < 40) return '$value $quote';
    final base = MoneyFormat.symbolOf(tender.pivotCurrency);
    return '$value $quote / $base';
  }
}
