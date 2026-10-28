import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le **jour** que porte une correction : celui du versement d'origine, que le
/// remplaçant garde.
///
/// En lecture seule. Un versement est daté du jour de sa saisie — l'antidatage
/// plaçait un numéro de reçu dans la pile d'un autre jour, et le promoteur
/// contrôle sa pile jour par jour (continuité des tickets, lot C). Une
/// correction n'antidate pas : c'est le même argent, déjà dans la pile du jour
/// d'origine.
///
/// Section à part entière, et non un champ glissé dans le bloc payeur : la date
/// ne dit rien de qui paie.
class FacturationCreatePaymentDateSection extends StatelessWidget {
  final DateTime paidAt;

  const FacturationCreatePaymentDateSection({super.key, required this.paidAt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloDateInput(
      label: l10n.facturationCreatePaymentDateLabel,
      placeholder: l10n.dateHint,
      value: paidAt,
      readOnly: true,
      firstDate: paidAt,
      lastDate: paidAt,
    );
  }
}
