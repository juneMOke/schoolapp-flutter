import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le **jour** que porte le versement — aujourd'hui par défaut, reculé quand on
/// rattrape une saisie tardive.
///
/// Section à part entière, et non un champ glissé dans le bloc payeur : la date
/// ne dit rien de qui paie. Elle vivait d'abord sous l'identité du payeur, où il
/// fallait expliquer en commentaire pourquoi elle échappait à la mention
/// « ces informations sont facultatives » — un widget qui doit plaider contre le
/// nom de ce qui l'entoure est au mauvais endroit.
///
/// Les bornes sont **fournies**, jamais devinées ici : la borne haute est le
/// jour courant de l'école (une date future ne s'offre pas, elle n'a donc jamais
/// à être refusée), la borne basse la rentrée de l'année que ce versement solde.
class FacturationCreatePaymentDateSection extends StatelessWidget {
  final DateTime paidAt;
  final DateTime firstPaidAt;
  final DateTime lastPaidAt;

  /// `null` fige la date — encaissement en vol, comme pour les autres champs.
  final ValueChanged<DateTime>? onPaidAtChanged;

  final bool readOnly;

  const FacturationCreatePaymentDateSection({
    super.key,
    required this.paidAt,
    required this.firstPaidAt,
    required this.lastPaidAt,
    this.onPaidAtChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloDateInput(
      label: l10n.facturationCreatePaymentDateLabel,
      placeholder: l10n.dateHint,
      value: paidAt,
      readOnly: readOnly,
      firstDate: firstPaidAt,
      lastDate: lastPaidAt,
      helpText: l10n.facturationCreatePaymentDateLabel,
      cancelText: l10n.cancel,
      confirmText: l10n.confirm,
      onChanged: (value) {
        // Le sélecteur ne rend `null` que si on l'annule : rien à propager, la
        // date précédente reste celle du versement.
        if (value != null) onPaidAtChanged?.call(value);
      },
    );
  }
}
