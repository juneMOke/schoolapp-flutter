import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_pdf_kit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Remet une pièce au **partage de l'appareil** : c'est là qu'on choisit
/// l'application qui envoie (Q4 — l'application n'envoie rien elle-même).
///
/// Une couture : les tests la remplacent, la page prend [shareNotifyPdf].
typedef FeeControlNotifyShare =
    Future<void> Function(Uint8List bytes, String fileName);

/// Partage par `Printing.sharePdf`. Un refus du canal natif (`false`) est un
/// échec comme un autre : la sur-couche le dit et garde le texte.
///
/// ⚠️ **Le partage dépose la pièce en clair** dans `cacheDir/share/` (cf.
/// `pubspec.yaml`), et cette relance nomme des élèves et des numéros de
/// parents. `SharedDocumentCache` la purge en fin de session — arbitrage
/// assumé, le même que la feuille d'appel et la liste de relance.
Future<void> shareNotifyPdf(Uint8List bytes, String fileName) async {
  final shared = await Printing.sharePdf(bytes: bytes, filename: fileName);
  if (!shared) throw StateError('share refused');
}

/// **La relance des parents**, en PDF : l'en-tête de l'école, le message tel
/// qu'il a été relu, puis la liste des destinataires (parent, téléphone,
/// élève) — de quoi l'envoyer, ou l'appeler, depuis n'importe quelle
/// application de l'appareil.
///
/// Feuille de travail locale, **pas une pièce scellée** : ni numéro ni
/// remontée, comme la feuille d'appel.
abstract final class FeeControlNotifyPdf {
  static const double phoneWidth = 120;

  /// Compose la relance puis la remet à [share], nommée « Relance des
  /// parents.pdf ». Lève si la composition ou le partage échoue.
  static Future<void> share(
    FeeControlNotifyShare share, {
    required String schoolName,
    required String context,
    required String message,
    required List<FeeControlNotifyRecipient> recipients,
    required DateTime issuedOn,
    required AppLocalizations l10n,
  }) async => share(
    await build(
      schoolName: schoolName,
      context: context,
      message: message,
      recipients: recipients,
      issuedOn: issuedOn,
      l10n: l10n,
    ),
    '${l10n.feeControlNotifyPdfTitle}.pdf',
  );

  static Future<Uint8List> build({
    required String schoolName,
    required String context,
    required String message,
    required List<FeeControlNotifyRecipient> recipients,
    required DateTime issuedOn,
    required AppLocalizations l10n,
  }) async {
    final document = pw.Document();
    final subtitle = [
      context,
      l10n.feeControlCallSheetIssuedOn(formatNotifyDate(issuedOn)),
    ].where((part) => part.isNotEmpty).join(' · ');

    document.addPage(
      pw.MultiPage(
        pageFormat: EnrollmentPdfKit.pageFormat,
        header: (_) => EnrollmentPdfKit.header(
          overtitle: schoolName,
          title: l10n.feeControlNotifyPdfTitle,
          subtitle: subtitle,
        ),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: EnrollmentPdfKit.muted, width: 0.5),
            ),
            child: pw.Text(
              message,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: EnrollmentPdfKit.bodySize,
                lineSpacing: 2,
              ),
            ),
          ),
          pw.SizedBox(height: 14),
          _table(recipients, l10n),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _table(
    List<FeeControlNotifyRecipient> recipients,
    AppLocalizations l10n,
  ) => pw.Table(
    columnWidths: {
      0: const pw.FlexColumnWidth(),
      1: const pw.FixedColumnWidth(phoneWidth),
      2: const pw.FlexColumnWidth(),
    },
    children: [
      pw.TableRow(
        decoration: EnrollmentPdfKit.headerRowDecoration,
        children: [
          EnrollmentPdfKit.headerCell(l10n.feeControlNotifyPdfParent),
          EnrollmentPdfKit.headerCell(l10n.feeControlNotifyPdfPhone),
          EnrollmentPdfKit.headerCell(l10n.feeControlColumnStudent),
        ],
      ),
      for (final (index, recipient) in recipients.indexed)
        pw.TableRow(
          decoration: EnrollmentPdfKit.rowDecoration(index),
          children: [
            EnrollmentPdfKit.cell(
              recipient.parentName ?? l10n.feeControlNotifyUnknownParent,
            ),
            // Sans numéro : un tiret, pas un blanc qui ferait croire à un oubli
            // d'impression.
            EnrollmentPdfKit.cell(
              recipient.hasPhone ? recipient.phoneNumber! : '—',
            ),
            EnrollmentPdfKit.cell(recipient.studentName),
          ],
        ),
    ],
  );
}
