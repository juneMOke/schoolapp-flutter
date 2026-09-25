import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le caissier a décidé : sur quelle imprimante, combien d'exemplaires.
class ThermalPrintChoice {
  final ThermalPrinter printer;
  final int copies;

  const ThermalPrintChoice({required this.printer, required this.copies});
}

/// Demande au caissier sur quelle imprimante sortir le ticket, et en combien
/// d'exemplaires.
///
/// Rend le choix, ou `null` s'il a fermé sans choisir.
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
///
/// ## Le compteur vit ici, et pas dans l'aperçu
///
/// Ce dialogue est redemandé à **chaque** ticket et ne concerne que la
/// thermique : c'est l'endroit où le nombre d'exemplaires se décide sans
/// toucher la visionneuse commune aux dix sorties papier. Le compteur se règle
/// **avant** de toucher l'imprimante — toucher une ligne lance l'impression.
/// [initialCopies] est le défaut de l'appelant, jamais mémorisé d'un ticket à
/// l'autre.
Future<ThermalPrintChoice?> showThermalPrinterPicker(
  BuildContext context, {
  required List<ThermalPrinter> printers,
  int initialCopies = TicketCopies.fallback,
}) {
  return showDialog<ThermalPrintChoice>(
    context: context,
    builder: (_) => _ThermalPrinterPickerDialog(
      printers: printers,
      initialCopies: TicketCopies.clamp(initialCopies),
    ),
  );
}

class _ThermalPrinterPickerDialog extends StatefulWidget {
  final List<ThermalPrinter> printers;
  final int initialCopies;

  const _ThermalPrinterPickerDialog({
    required this.printers,
    required this.initialCopies,
  });

  @override
  State<_ThermalPrinterPickerDialog> createState() =>
      _ThermalPrinterPickerDialogState();
}

class _ThermalPrinterPickerDialogState
    extends State<_ThermalPrinterPickerDialog> {
  late int _copies = widget.initialCopies;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      title: Text(l10n.ticketPrinterPickerTitle),
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      content: SizedBox(
        width: AppDimensions.ticketPrinterPickerWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CopiesStepper(
              copies: _copies,
              onChanged: (value) => setState(() => _copies = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final printer in widget.printers)
                    ListTile(
                      leading: const Icon(Icons.print_outlined),
                      // Le nom d'usine est le même sur deux NT-8003DD d'un même
                      // établissement : l'adresse est ce qui les distingue,
                      // elle est donc montrée, pas cachée derrière un libellé
                      // rassurant.
                      title: Text(
                        printer.name.isEmpty
                            ? l10n.ticketPrinterUnnamed
                            : printer.name,
                      ),
                      subtitle: Text(printer.macAddress),
                      onTap: () => Navigator.of(context).pop(
                        ThermalPrintChoice(printer: printer, copies: _copies),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

/// « Exemplaires  (−) 2 (+) ».
///
/// Les deux bornes **désactivent** leur bouton plutôt que de le cacher : le
/// compteur ne change pas de forme sous le doigt.
class _CopiesStepper extends StatelessWidget {
  final int copies;
  final ValueChanged<int> onChanged;

  const _CopiesStepper({required this.copies, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.ticketCopiesLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.ticketCopiesDecrease,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.textPrimary,
            onPressed: copies > TicketCopies.min
                ? () => onChanged(copies - 1)
                : null,
          ),
          SizedBox(
            width: AppDimensions.ticketCopiesValueWidth,
            child: Text(
              '$copies',
              key: const ValueKey('ticketCopiesValue'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.ticketCopiesIncrease,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.textPrimary,
            onPressed: copies < TicketCopies.max
                ? () => onChanged(copies + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
