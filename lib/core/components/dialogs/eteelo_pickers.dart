import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';

/// Mode d'ouverture du calendrier : au clavier physique, la date se tape
/// (« 12/03/1998 ») — remonter jusqu'à une naissance au calendrier coûte des
/// dizaines de clics. Sur la tablette, le calendrier reste le geste naturel.
/// Les deux modes restent accessibles par l'icône du sélecteur.
DatePickerEntryMode get eteeloDateEntryMode => expectsPhysicalKeyboard
    ? DatePickerEntryMode.input
    : DatePickerEntryMode.calendar;

/// [showDatePicker] ouvert dans le mode qui convient à l'appareil
/// ([eteeloDateEntryMode]) : le seul point d'entrée des sélecteurs de date.
Future<DateTime?> showEteeloDatePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
  Locale? locale,
  String? helpText,
  String? cancelText,
  String? confirmText,
  TransitionBuilder? builder,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  initialEntryMode: eteeloDateEntryMode,
  locale: locale,
  helpText: helpText,
  cancelText: cancelText,
  confirmText: confirmText,
  builder: builder,
);

/// [showTimePicker] en saisie au clavier physique plutôt qu'au cadran.
Future<TimeOfDay?> showEteeloTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TransitionBuilder? builder,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  initialEntryMode: expectsPhysicalKeyboard
      ? TimePickerEntryMode.input
      : TimePickerEntryMode.dial,
  builder: builder,
);
