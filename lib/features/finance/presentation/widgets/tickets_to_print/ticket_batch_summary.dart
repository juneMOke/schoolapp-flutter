import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/ticket_batch_print_flow.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le lot dit en se terminant ; `null` quand il n'a rien à dire.
///
/// Un lot arrêté n'imprime **rien** en PDF : la cause se dit seule, sans le
/// « impression PDF à la place » du ticket isolé.
({String text, bool offersSettings})? ticketBatchSummary(
  AppLocalizations l10n,
  TicketBatchOutcome outcome,
) {
  final problem = outcome.problem;
  final lines = [
    if (outcome.printed > 0) l10n.ticketsToPrintDone(outcome.printed),
    if (outcome.printed > 0 && outcome.printer != null)
      l10n.ticketsPrinterUsed(outcome.printer!.label),
    if (outcome.spoolerFailed) l10n.ticketPrintFailed,
    if (problem != null)
      l10n.ticketsToPrintStopped(thermalPrinterProblemCause(l10n, problem)),
    if (outcome.skipped > 0) l10n.ticketsToPrintSkipped(outcome.skipped),
  ];
  if (lines.isEmpty) return null;
  return (
    text: lines.join('\n'),
    offersSettings: problem == ThermalPrinterProblem.permissionDenied,
  );
}
