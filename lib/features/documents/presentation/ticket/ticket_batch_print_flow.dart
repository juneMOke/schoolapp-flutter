import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_cancellation_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/cancellation_ticket_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_printer_picker.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/features/school/data/school_logo_band_loader.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qu'un lot a produit.
class TicketBatchOutcome {
  /// Tickets sortis.
  final int printed;

  /// Tickets écartés sans toucher à l'imprimante — élève pas encore descendu,
  /// numéro retiré entre la lecture et l'envoi. Ils restent dans la file.
  final int skipped;

  /// Le lot s'est arrêté sur une panne d'imprimante, `null` sinon.
  final ThermalPrinterProblem? problem;

  /// Le caissier a refermé le choix de l'imprimante : rien n'est parti.
  final bool cancelled;

  const TicketBatchOutcome({
    this.printed = 0,
    this.skipped = 0,
    this.problem,
    this.cancelled = false,
  });
}

/// Imprime [jobs] — les tickets cochés de « Tickets à imprimer », dans
/// l'ordre des numéros (continuité des tickets RC, lot D).
///
/// L'imprimante se choisit **une fois** pour le lot, avec le nombre
/// d'exemplaires de l'école : la redemander à chaque ticket rendrait le lot
/// inutilisable, la mémoriser ferait sortir des reçus dans la pièce d'à côté.
/// Puis les tickets partent **un par un** : chacun est marqué imprimé dès que
/// SON envoi a réussi, et la première panne arrête le lot — les suivants
/// restent dans la file, cochés, prêts à relancer.
///
/// Pas de repli PDF ici, contrairement au ticket de l'écran de succès : le
/// parent n'est plus au guichet, le papier est celui de la pile du promoteur,
/// et il attend sans dommage que l'imprimante revienne.
Future<TicketBatchOutcome> printTicketBatch(
  BuildContext context, {
  required List<TicketPrintJob> jobs,
}) async {
  if (jobs.isEmpty) return const TicketBatchOutcome();
  final l10n = AppLocalizations.of(context)!;
  final receiptLabels = provisionalTicketLabels(l10n);
  final cancellationLabels = cancellationTicketLabels(l10n);

  final logoBand = await getIt<SchoolLogoBandLoader>().thermalBand(
    getIt<CurrentUserContext>().schoolId,
  );
  final copies = await getIt<ResolveTicketCopiesUseCase>()();
  if (!context.mounted) return const TicketBatchOutcome(cancelled: true);

  final chosen = await chooseThermalPrinter(context, initialCopies: copies);
  ThermalPrintChoice? choice;
  ThermalPrinterProblem? refused;
  chosen.fold((outcome) {
    if (outcome is ThermalTicketFailed) refused = outcome.problem;
  }, (value) => choice = value);
  final printer = choice;
  if (printer == null) {
    return TicketBatchOutcome(problem: refused, cancelled: refused == null);
  }

  final markPrinted = getIt<MarkTicketJobPrintedUseCase>();
  final recordProblem = getIt<RecordTicketJobProblemUseCase>();
  var printed = 0;
  var skipped = 0;
  for (final job in jobs) {
    final bytes = await _bytesOf(
      job,
      receiptLabels: receiptLabels,
      cancellationLabels: cancellationLabels,
      logoBand: logoBand,
    );
    if (bytes == null) {
      skipped++;
      continue;
    }
    final problem = await sendThermalBytes(bytes, printer);
    if (problem != null) {
      await recordProblem(job, problem.name);
      return TicketBatchOutcome(
        printed: printed,
        skipped: skipped,
        problem: problem,
      );
    }
    // Une note de suivi ratée n'annule pas le papier : il est sorti. Le
    // ticket reste au pire dans la file, et le caissier le voit encore.
    await markPrinted(job);
    printed++;
  }
  return TicketBatchOutcome(printed: printed, skipped: skipped);
}

/// Le flux ESC/POS d'un ticket, `null` quand il ne doit pas sortir.
Future<Uint8List?> _bytesOf(
  TicketPrintJob job, {
  required TicketLabels receiptLabels,
  required TicketCancellationLabels cancellationLabels,
  TicketLogoBand? logoBand,
}) async {
  switch (job.kind) {
    case TicketPrintJobKind.receipt:
      final built = await getIt<BuildProvisionalTicketUseCase>()(
        paymentId: job.paymentId,
        labels: receiptLabels,
      );
      final model = built.fold((_) => null, (model) => model);
      // Un ticket qui ne nomme personne n'atteste rien (ADR-015 F1).
      if (model == null || model.studentFullName.trim().isEmpty) return null;
      return EscPosTicketRenderer.render(model, logoBand: logoBand);
    case TicketPrintJobKind.cancellation:
      final built = await getIt<BuildCancellationTicketUseCase>()(
        paymentId: job.paymentId,
        labels: cancellationLabels,
      );
      final model = built.fold((_) => null, (model) => model);
      if (model == null || model.studentFullName.trim().isEmpty) return null;
      return EscPosTicketRenderer.renderRichLines(
        TicketCancellationLayout.renderRich(model),
        logoBand: logoBand,
      );
  }
}
