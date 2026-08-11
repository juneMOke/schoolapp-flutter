import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Demande au caissier sur quelle imprimante sortir le ticket.
///
/// Rend l'imprimante choisie, ou `null` s'il a fermé sans choisir.
///
/// ## Un sélecteur, et rien d'autre
///
/// [printers] est **garantie non vide** par l'appelant, et déjà résolue. Ce
/// dialogue n'a donc ni chargement, ni vide, ni erreur à afficher : lire les
/// appareils appairés, constater les permissions et interpréter un échec sont
/// des questions qui se tranchent **avant** de l'ouvrir, là où elles peuvent
/// mener à un repli PDF plutôt qu'à une liste vide devant laquelle le caissier
/// n'aurait rien à faire.
///
/// C'est aussi ce qui le garde hors du champ de la règle des états partagés :
/// il n'y a pas de zone de résultats ici, seulement un choix.
Future<ThermalPrinter?> showThermalPrinterPicker(
  BuildContext context, {
  required List<ThermalPrinter> printers,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<ThermalPrinter>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      title: Text(l10n.ticketPrinterPickerTitle),
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      content: SizedBox(
        width: AppDimensions.ticketPrinterPickerWidth,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final printer in printers)
              ListTile(
                leading: const Icon(Icons.print_outlined),
                // Le nom d'usine est le même sur deux NT-8003DD d'un même
                // établissement : l'adresse est ce qui les distingue, elle est
                // donc montrée, pas cachée derrière un libellé rassurant.
                title: Text(
                  printer.name.isEmpty
                      ? l10n.ticketPrinterUnnamed
                      : printer.name,
                ),
                subtitle: Text(printer.macAddress),
                onTap: () => Navigator.of(dialogContext).pop(printer),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  );
}
