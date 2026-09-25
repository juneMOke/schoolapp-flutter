import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le nombre d'exemplaires qu'un ticket sort d'office dans l'école.
///
/// Ce n'est qu'un **point de départ** : le compteur du sélecteur d'imprimante
/// part de cette valeur, et le caissier l'ajuste ticket par ticket.
///
/// Facultatif. Tant que l'école n'a rien choisi, le champ montre le défaut
/// (« 1 (par défaut) ») plutôt qu'une case vide : c'est ce qui sortira. Il n'y
/// a pas d'option « aucun » — une valeur enregistrée ne se vide pas côté
/// serveur, et revenir au comportement d'avant, c'est choisir 1.
class SchoolTicketCopiesSelect extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;

  const SchoolTicketCopiesSelect({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = value;

    return EteeloSelectInput<int>(
      label: l10n.configurationSchoolTicketCopies,
      helperText: l10n.configurationSchoolTicketCopiesHelper,
      placeholder: l10n.configurationSchoolTicketCopiesDefault(
        TicketCopies.fallback,
      ),
      // Une valeur hors bornes venue d'ailleurs n'est pas proposée : on montre
      // alors le défaut, jamais une sélection que la liste ne contient pas.
      value: current == null || current != TicketCopies.clamp(current)
          ? null
          : current,
      items: [
        for (var n = TicketCopies.min; n <= TicketCopies.max; n++)
          EteeloSelectItem<int>(value: n, label: '$n'),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
