import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_layout.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_cancellation_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/cancellation_ticket_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/features/school/data/school_logo_band_loader.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Imprime le ticket d'annulation du versement [paymentId] sur la thermique
/// (continuité des tickets RC, lot B) — à la fin du geste d'annulation, ou
/// depuis le détail d'un versement annulé.
///
/// Pas de repli PDF : ce papier est celui de la pile du promoteur, il attend
/// sans dommage dans « Tickets à imprimer » si l'imprimante manque.
///
/// Rend `true` quand le papier est sorti ; la file le sait alors.
Future<bool> printCancellationTicket(
  BuildContext context, {
  required String paymentId,
  required ScaffoldMessengerState? messenger,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final built = await getIt<BuildCancellationTicketUseCase>()(
    paymentId: paymentId,
    labels: cancellationTicketLabels(l10n),
  );
  final model = built.fold((_) => null, (model) => model);
  if (model == null) {
    final awaiting = built.fold(
      (failure) => failure is ReceiptAwaitingNumberFailure,
      (_) => false,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          awaiting ? l10n.ticketAwaitingNumber : l10n.ticketPrintFailed,
        ),
      ),
    );
    return false;
  }
  // Un ticket qui ne nomme personne n'atteste rien (ADR-015 F1).
  if (model.studentFullName.trim().isEmpty) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.ticketRefusedUnknownStudent)),
    );
    return false;
  }

  final logoBand = await getIt<SchoolLogoBandLoader>().thermalBand(
    getIt<CurrentUserContext>().schoolId,
  );
  final copies = await getIt<ResolveTicketCopiesUseCase>()();
  if (!context.mounted) return false;

  final outcome = await printThermalBytes(
    context,
    bytes: EscPosTicketRenderer.renderRichLines(
      TicketCancellationLayout.renderRich(model),
      logoBand: logoBand,
    ),
    initialCopies: copies,
  );
  switch (outcome) {
    case ThermalTicketPrinted():
      await getIt<MarkCancellationTicketPrintedUseCase>()(paymentId);
      return true;
    case ThermalTicketFailed(:final problem):
      messenger?.showSnackBar(
        SnackBar(content: Text(thermalPrinterProblemMessage(l10n, problem))),
      );
      return false;
    case ThermalTicketCancelled() || ThermalTicketNoSurface():
      return false;
  }
}
