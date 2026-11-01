import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_cancellation_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/cancellation_ticket_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_printer.dart';
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

  /// Le caissier a refermé l'aperçu ou le choix de l'imprimante : rien n'est
  /// parti.
  final bool cancelled;

  /// Le spouleur a refusé le lot.
  final bool spoolerFailed;

  const TicketBatchOutcome({
    this.printed = 0,
    this.skipped = 0,
    this.problem,
    this.cancelled = false,
    this.spoolerFailed = false,
  });
}

/// Le lot composé, une fois pour l'aperçu et l'imprimante : le papier montré
/// est le papier tiré.
class _ComposedBatch {
  final List<(TicketPrintJob, List<TicketLine>)> tickets;
  final int skipped;
  final TicketLogoBand? logoBand;
  final int copies;

  const _ComposedBatch({
    required this.tickets,
    required this.skipped,
    required this.logoBand,
    required this.copies,
  });
}

/// Le bouton de « Tickets à imprimer » : le même cheminement que tout autre
/// ticket. Les tickets cochés s'ouvrent dans la visionneuse, rien ne part sans
/// appui sur « Imprimer », puis la thermique sur tablette, le spouleur sur le
/// poste et le navigateur.
///
/// Le spouleur ne prouve aucun papier : il rend la main dès qu'il accepte le
/// document, « Enregistrer en PDF » compris. Le caissier dit alors si les
/// tickets sont sortis, et eux seuls quittent la file. Sans cette question, le
/// poste ne viderait jamais sa liste.
///
/// [previewBuilder] substitue l'aperçu pour les tests, comme dans
/// `printProvisionalTicketWithFallback`.
Future<TicketBatchOutcome> reviewAndPrintTicketBatch(
  BuildContext context, {
  required List<TicketPrintJob> jobs,
  ThermalPrinterChooser choose = chooseThermalPrinter,
  ThermalBytesSender send = sendThermalBytes,
  Widget Function(BuildContext context, PrintableDocument document)?
  previewBuilder,
}) async {
  if (jobs.isEmpty) return const TicketBatchOutcome();
  final l10n = AppLocalizations.of(context)!;
  final cutNotice = l10n.ticketCutNotice;
  final batch = await _compose(l10n, jobs);
  if (batch.tickets.isEmpty) return TicketBatchOutcome(skipped: batch.skipped);

  final tickets = [for (final (_, lines) in batch.tickets) lines];
  final preview = await PdfTicketRenderer.renderTickets(
    tickets,
    format: PdfPageFormat.a4,
    cutNotice: cutNotice,
    logoBand: batch.logoBand,
  );
  if (!context.mounted) return const TicketBatchOutcome(cancelled: true);

  var outcome = TicketBatchOutcome(skipped: batch.skipped, cancelled: true);
  await showEteeloDocumentViewer(
    context,
    title: l10n.ticketsToPrintTitle,
    document: PrintableDocument(
      bytes: preview,
      fileName: '${l10n.ticketsToPrintTitle}.pdf',
      reference: l10n.ticketsToPrintTitle,
    ),
    previewBuilder: previewBuilder,
    closeAfterPrint: true,
    onPrint: () async {
      outcome = printsTicketsThroughSpooler
          ? await _sendToSpooler(
              context,
              batch,
              tickets: tickets,
              cutNotice: cutNotice,
              l10n: l10n,
            )
          : await _sendToThermalPrinter(
              context,
              batch,
              choose: choose,
              send: send,
            );
    },
  );
  return outcome;
}

Future<TicketBatchOutcome> _sendToSpooler(
  BuildContext context,
  _ComposedBatch batch, {
  required List<List<TicketLine>> tickets,
  required String cutNotice,
  required AppLocalizations l10n,
}) async {
  final accepted = await printTickets(
    tickets: tickets,
    name: l10n.ticketsToPrintTitle,
    cutNotice: cutNotice,
    logoBand: batch.logoBand,
    copies: batch.copies,
  );
  if (!accepted) {
    return TicketBatchOutcome(skipped: batch.skipped, spoolerFailed: true);
  }
  if (!context.mounted) return TicketBatchOutcome(skipped: batch.skipped);
  final paperOut = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.ticketsToPrintPaperOutTitle),
      content: Text(l10n.ticketsToPrintPaperOutMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.ticketsToPrintPaperOutNo),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.ticketsToPrintPaperOutYes),
        ),
      ],
    ),
  );
  if (paperOut != true) return TicketBatchOutcome(skipped: batch.skipped);

  final markPrinted = getIt<MarkTicketJobPrintedUseCase>();
  for (final (job, _) in batch.tickets) {
    await markPrinted(job);
  }
  return TicketBatchOutcome(
    printed: batch.tickets.length,
    skipped: batch.skipped,
  );
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
///
/// [choose] et [send] sont les deux bouts matériels du lot — le sélecteur et
/// le canal Bluetooth ; les tests y branchent les leurs.
Future<TicketBatchOutcome> printTicketBatch(
  BuildContext context, {
  required List<TicketPrintJob> jobs,
  ThermalPrinterChooser choose = chooseThermalPrinter,
  ThermalBytesSender send = sendThermalBytes,
}) async {
  if (jobs.isEmpty) return const TicketBatchOutcome();
  final batch = await _compose(AppLocalizations.of(context)!, jobs);
  if (!context.mounted) return const TicketBatchOutcome(cancelled: true);
  return _sendToThermalPrinter(context, batch, choose: choose, send: send);
}

Future<TicketBatchOutcome> _sendToThermalPrinter(
  BuildContext context,
  _ComposedBatch batch, {
  required ThermalPrinterChooser choose,
  required ThermalBytesSender send,
}) async {
  final chosen = await choose(context, initialCopies: batch.copies);
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
  for (final (job, lines) in batch.tickets) {
    final problem = await send(
      EscPosTicketRenderer.renderRichLines(lines, logoBand: batch.logoBand),
      printer,
    );
    if (problem != null) {
      await recordProblem(job, problem.name);
      return TicketBatchOutcome(
        printed: printed,
        skipped: batch.skipped,
        problem: problem,
      );
    }
    // Une note de suivi ratée n'annule pas le papier : il est sorti. Le
    // ticket reste au pire dans la file, et le caissier le voit encore.
    await markPrinted(job);
    printed++;
  }
  return TicketBatchOutcome(printed: printed, skipped: batch.skipped);
}

Future<_ComposedBatch> _compose(
  AppLocalizations l10n,
  List<TicketPrintJob> jobs,
) async {
  final receiptLabels = provisionalTicketLabels(l10n);
  final cancellationLabels = cancellationTicketLabels(l10n);
  final logoBand = await getIt<SchoolLogoBandLoader>().thermalBand(
    getIt<CurrentUserContext>().schoolId,
  );
  final copies = await getIt<ResolveTicketCopiesUseCase>()();
  final tickets = <(TicketPrintJob, List<TicketLine>)>[];
  var skipped = 0;
  for (final job in jobs) {
    final lines = await _linesOf(
      job,
      receiptLabels: receiptLabels,
      cancellationLabels: cancellationLabels,
    );
    if (lines == null) {
      skipped++;
    } else {
      tickets.add((job, lines));
    }
  }
  return _ComposedBatch(
    tickets: tickets,
    skipped: skipped,
    logoBand: logoBand,
    copies: copies,
  );
}

/// Les lignes d'un ticket, `null` quand il ne doit pas sortir.
Future<List<TicketLine>?> _linesOf(
  TicketPrintJob job, {
  required TicketLabels receiptLabels,
  required TicketCancellationLabels cancellationLabels,
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
      return TicketTextLayout.renderRich(model);
    case TicketPrintJobKind.cancellation:
      final built = await getIt<BuildCancellationTicketUseCase>()(
        paymentId: job.paymentId,
        labels: cancellationLabels,
      );
      final model = built.fold((_) => null, (model) => model);
      if (model == null || model.studentFullName.trim().isEmpty) return null;
      return TicketCancellationLayout.renderRich(model);
  }
}
