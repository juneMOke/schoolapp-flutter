import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/ticket_printer/ticket_printer_settings_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'imprimante de ce guichet, parmi les appairées, et son ticket d'essai.
class TicketPrinterChoiceSection extends StatelessWidget {
  final TicketPrinterSettingsState state;
  final ValueChanged<ThermalPrinter> onSelect;
  final VoidCallback onTest;

  const TicketPrinterChoiceSection({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = state.selected;
    final hint = _hint(l10n);
    return EteeloPanelCard(
      title: l10n.ticketPrinterTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) _Note(hint),
          for (final printer in state.printers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              leading: const Icon(Icons.print_outlined),
              // Deux NT-8003DD d'une même école portent le même nom :
              // l'adresse les distingue, elle reste visible.
              title: Text(
                printer.name.isEmpty ? l10n.ticketPrinterUnnamed : printer.name,
              ),
              subtitle: Text(printer.macAddress),
              selected: printer.macAddress == selected?.macAddress,
              trailing: printer.macAddress == selected?.macAddress
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
              // L'essai en cours garde la liaison : pas de changement pendant.
              onTap: state.test == TicketPrinterTest.sending
                  ? null
                  : () => onSelect(printer),
            ),
          if (selected != null &&
              state.printers.isNotEmpty &&
              !state.selectedGone)
            ..._test(l10n, selected),
        ],
      ),
    );
  }

  String? _hint(AppLocalizations l10n) {
    if (state.missing.isNotEmpty) return l10n.ticketPrinterWaitPermission;
    return switch (state.problem) {
      ThermalPrinterProblem.bluetoothOff => l10n.ticketPrinterBluetoothOffHint,
      ThermalPrinterProblem.noPrinterSelected => l10n.ticketPrinterPairHint,
      ThermalPrinterProblem.unreachable ||
      ThermalPrinterProblem.permissionDenied =>
        l10n.ticketPrinterUnreachableHint,
      null when state.selectedGone => l10n.ticketPrinterGone(
        state.selected!.label,
      ),
      null when state.selected == null => l10n.ticketPrinterChoose,
      null => null,
    };
  }

  List<Widget> _test(AppLocalizations l10n, ThermalPrinter selected) {
    final problem = state.testProblem;
    return [
      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: EteeloButton.secondary(
          label: l10n.ticketPrinterTestPrint,
          icon: Icons.receipt_long_outlined,
          isLoading: state.test == TicketPrinterTest.sending,
          onPressed: state.test == TicketPrinterTest.sending ? null : onTest,
          fullWidth: false,
        ),
      ),
      if (state.test == TicketPrinterTest.sent)
        _Note(
          l10n.ticketPrinterTestSent((state.testPrinter ?? selected).label),
        ),
      if (state.test == TicketPrinterTest.failed && problem != null)
        _Note(
          l10n.ticketPrinterTestFailed(
            thermalPrinterProblemCause(l10n, problem),
          ),
          error: true,
        ),
    ];
  }
}

class _Note extends StatelessWidget {
  final String text;
  final bool error;

  const _Note(this.text, {this.error = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
    child: Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: error ? AppColors.error : AppColors.textSecondary,
      ),
    ),
  );
}
