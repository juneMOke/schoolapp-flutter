import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/data/ticket/sale_ticket_composer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_text_layout.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_labels_factory.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_printer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/ticket_copies_stepper.dart';
import 'package:school_app_flutter/features/school/data/school_logo_band_loader.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre le ticket de vente au comptoir, puis l'imprime — **le même chemin que
/// le ticket de perception** : aperçu, thermique Bluetooth sur la tablette,
/// imprimante du système sur un poste de bureau, et PDF en filet quand la
/// thermique est absente ou en échec.
///
/// ⚠️ **Rien ici n'est un échec d'encaissement.** La vente est déjà écrite
/// localement : tout ce qui suit ne coûte que du papier.
///
/// ⚠️ **Pas de numéro définitif, pas de ticket.** Tant que le reçu de vente
/// n'est pas scellé, un message le dit et rien ne s'ouvre.
///
/// Les deux sorties partent des **mêmes lignes**, composées une seule fois :
/// l'aperçu ne doit pas pouvoir montrer un papier que l'imprimante ne sortira
/// pas.
///
/// Rend **vrai si la thermique a sorti le papier** — et rien d'autre, comme le
/// ticket de perception : l'appelant s'en sert pour noter la trace
/// d'impression, et un envoi par le système ne dit pas si la feuille est sortie.
///
/// [previewBuilder] substitue l'aperçu, et c'est la seule façon de tester ce
/// flux : le vrai `PdfPreview` rasterise par canal de plateforme.
Future<bool> printSaleTicket(
  BuildContext context, {
  required RecordedSale sale,
  required Map<String, String> levelLabels,
  required ScaffoldMessengerState? messenger,
  Widget Function(BuildContext context, PrintableDocument document)?
  previewBuilder,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // Tout ce qui vient du contexte est prélevé MAINTENANT : ce qui suit doit
  // pouvoir aboutir alors que l'écran a changé.
  final labels = saleTicketLabelsOf(l10n);
  final cutNotice = l10n.ticketCutNotice;

  final built = await getIt<SaleTicketComposer>().compose(
    sale,
    labels: labels,
    levelLabels: levelLabels,
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
          awaiting
              ? l10n.boutiqueTicketAwaitingNumber
              : l10n.boutiqueReceiptPrintFailed,
        ),
      ),
    );
    return false;
  }

  // Le point de départ du compteur d'exemplaires : le réglage de l'école, ou
  // un — le même que pour le ticket de perception.
  final defaultCopies = await getIt<ResolveTicketCopiesUseCase>()();
  final logoBand = await getIt<SchoolLogoBandLoader>().thermalBand(
    sale.sale.schoolId,
  );
  if (!context.mounted) return false;

  // Une seule composition, toutes les sorties : le papier montré est le papier
  // tiré. Le PDF se compose sur une FEUILLE pour l'aperçu — une page de hauteur
  // infinie ne se rasterise pas à l'écran.
  final lines = SaleTicketTextLayout.renderRich(model);
  final preview = await PdfTicketRenderer.renderRichLines(
    lines,
    format: PdfPageFormat.a4,
    cutNotice: cutNotice,
    logoBand: logoBand,
  );
  if (!context.mounted) return false;

  var printed = false;
  final copies = ValueNotifier(defaultCopies);
  final paper = _SalePaper(
    lines: lines,
    name: model.receiptNumber,
    cutNotice: cutNotice,
    logoBand: logoBand,
  );
  await showEteeloDocumentViewer(
    context,
    title: model.labels.documentTitle,
    document: PrintableDocument(
      bytes: preview,
      fileName: '${model.receiptNumber}.pdf',
      reference: model.receiptNumber,
    ),
    previewBuilder: previewBuilder,
    printOptions: TicketCopiesOption(copies: copies),
    // Le ticket est tiré : l'aperçu se referme, et le message d'échec éventuel
    // redevient atteignable — sous une modale, ses appuis seraient avalés.
    closeAfterPrint: true,
    onPrint: () async {
      if (printsTicketsThroughSpooler) {
        final sent = await paper.toSystemPrinter(copies.value);
        if (!sent) _notify(messenger, l10n.boutiqueReceiptPrintFailed);
        return;
      }
      printed = await _printThermal(
        context,
        paper: paper,
        copies: copies.value,
        messenger: messenger,
        l10n: l10n,
      );
    },
  );
  copies.dispose();
  return printed;
}

/// La thermique d'abord, le PDF en filet — la politique du ticket de
/// perception (`printProvisionalTicketWithFallback`).
Future<bool> _printThermal(
  BuildContext context, {
  required _SalePaper paper,
  required int copies,
  required ScaffoldMessengerState? messenger,
  required AppLocalizations l10n,
}) async {
  final outcome = await printThermalBytes(
    context,
    bytes: EscPosTicketRenderer.renderRichLines(
      paper.lines,
      logoBand: paper.logoBand,
    ),
    initialCopies: copies,
  );

  switch (outcome) {
    case ThermalTicketPrinted(:final printer):
      _notify(
        messenger,
        printer == null
            ? l10n.boutiqueReceiptPrinted
            : l10n.boutiqueReceiptPrintedOn(printer.label),
      );
      return true;

    // Le caissier a fermé la liste : le geste demandé a été repris. Insister
    // par un message serait lui reprocher son propre choix.
    case ThermalTicketCancelled():
      return false;

    // Aucune thermique joignable sur ce poste : le système imprime le PDF.
    case ThermalTicketNoSurface():
      await paper.toSystemPrinter(copies);
      return false;

    // La cause d'abord, nommée, puis le filet PDF pour que le client reparte
    // avec un papier.
    case ThermalTicketFailed(problem: final problem, copies: final chosen):
      messenger?.showSnackBar(
        SnackBar(
          content: Text(thermalPrinterProblemMessage(l10n, problem)),
          action: problem == ThermalPrinterProblem.permissionDenied
              ? SnackBarAction(
                  label: l10n.settings,
                  onPressed: () =>
                      getIt<ThermalPrinterPermission>().openSettings(),
                )
              : null,
        ),
      );
      final sent = await paper.toSystemPrinter(chosen ?? copies);
      if (!sent) _notify(messenger, l10n.boutiqueReceiptPrintFailed);
      return false;
  }
}

void _notify(ScaffoldMessengerState? messenger, String message) =>
    messenger?.showSnackBar(SnackBar(content: Text(message)));

/// Le papier composé, et sa sortie par l'imprimante du système.
class _SalePaper {
  final List<TicketLine> lines;
  final String name;
  final String cutNotice;
  final TicketLogoBand? logoBand;

  const _SalePaper({
    required this.lines,
    required this.name,
    required this.cutNotice,
    required this.logoBand,
  });

  Future<bool> toSystemPrinter(int copies) => printTicketLines(
    lines: lines,
    name: name,
    cutNotice: cutNotice,
    logoBand: logoBand,
    copies: copies,
  );
}
