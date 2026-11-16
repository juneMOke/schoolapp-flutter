import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Le choix d'une date de la trésorerie (journée de Clôture, bornes d'une
/// période libre).
///
/// Sur un poste et sur le web, il s'ouvre sur la **saisie** (« 12/10/2026 »)
/// : on a un clavier, et taper une date va plus vite que remonter mois par
/// mois dans le calendrier. L'icône du calendrier reste dans la modale. Au
/// doigt, il s'ouvre sur le calendrier.
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
  initialEntryMode: treasuryTypesDates
      ? DatePickerEntryMode.input
      : DatePickerEntryMode.calendar,
);

/// Un poste ou le web : la date se tape au clavier.
bool get treasuryTypesDates =>
    kIsWeb ||
    !(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
