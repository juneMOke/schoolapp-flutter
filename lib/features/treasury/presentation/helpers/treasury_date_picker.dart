import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/device/pointer_kind_scope.dart';

/// Le choix d'une date de la trésorerie (journée de Clôture, bornes d'une
/// période libre).
///
/// À la souris, il s'ouvre sur la **saisie** (« 12/10/2026 ») : un clavier
/// est là, et taper une date va plus vite que remonter mois par mois dans le
/// calendrier. L'icône du calendrier reste dans la modale. Au doigt — la
/// tablette, mais aussi la version web ouverte sur un téléphone — il s'ouvre
/// sur le calendrier : la saisie y ferait surgir le clavier virtuel.
Future<DateTime?> showTreasuryDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  SelectableDayPredicate? selectableDayPredicate,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  selectableDayPredicate: selectableDayPredicate,
  initialEntryMode: PointerKindScope.usesMouseNow(context)
      ? DatePickerEntryMode.input
      : DatePickerEntryMode.calendar,
);
