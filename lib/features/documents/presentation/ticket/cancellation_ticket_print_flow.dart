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
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_cancellation_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/cancellation_ticket_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_printer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/features/school/data/school_logo_band_loader.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre le ticket d'annulation du versement [paymentId], puis l'imprime
/// depuis le pied de l'aperçu (continuité des tickets RC, lot B) — à la fin du
/// geste d'annulation, ou depuis le détail d'un versement annulé.
///
/// Même geste que le ticket de caisse : rien ne part tant que personne n'a
/// appuyé sur « Imprimer », et la sortie est la thermique sur tablette, le
/// spouleur sur le poste et le navigateur.
///
/// Pas de repli PDF sur tablette : ce papier est celui de la pile du promoteur,
/// il attend sans dommage dans « Tickets à imprimer » si l'imprimante manque.
///
/// Rend `true` quand la thermique a sorti le papier ; la file le sait alors. Le
/// spouleur ne le prouve pas : il rend la main dès qu'il accepte le document.
///
/// [previewBuilder] substitue l'aperçu pour les tests, comme dans
/// `printProvisionalTicketWithFallback`.
Future<bool> printCancellationTicket(
  BuildContext context, {
  required String paymentId,
  required ScaffoldMessengerState? messenger,
  Widget Function(BuildContext context, PrintableDocument document)?
  previewBuilder,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final cutNotice = l10n.ticketCutNotice;
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
  final lines = TicketCancellationLayout.renderRich(model);
  // Sur une feuille : le rouleau a une hauteur infinie, qu'un aperçu ne sait
  // pas mesurer. Les lignes montrées sont celles qui partent à l'imprimante.
  final preview = await PdfTicketRenderer.renderRichLines(
    lines,
    format: PdfPageFormat.a4,
    cutNotice: cutNotice,
    logoBand: logoBand,
  );
  if (!context.mounted) return false;

  var printed = false;
  await showEteeloDocumentViewer(
    context,
    title: model.labels.title,
    document: PrintableDocument(
      bytes: preview,
      fileName: '${model.receiptNumber}.pdf',
      reference: model.receiptNumber,
    ),
    previewBuilder: previewBuilder,
    closeAfterPrint: true,
    onPrint: () async {
      if (printsTicketsThroughSpooler) {
        final accepted = await printTicketLines(
          lines: lines,
          name: model.receiptNumber,
          cutNotice: cutNotice,
          logoBand: logoBand,
          copies: copies,
        );
        if (!accepted) {
          messenger?.showSnackBar(
            SnackBar(content: Text(l10n.ticketPrintFailed)),
          );
        }
        return;
      }
      printed = await _sendToThermalPrinter(
        context,
        paymentId: paymentId,
        lines: lines,
        logoBand: logoBand,
        copies: copies,
        messenger: messenger,
        l10n: l10n,
      );
    },
  );
  return printed;
}

Future<bool> _sendToThermalPrinter(
  BuildContext context, {
  required String paymentId,
  required List<TicketLine> lines,
  required TicketLogoBand? logoBand,
  required int copies,
  required ScaffoldMessengerState? messenger,
  required AppLocalizations l10n,
}) async {
  final outcome = await printThermalBytes(
    context,
    bytes: EscPosTicketRenderer.renderRichLines(lines, logoBand: logoBand),
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
