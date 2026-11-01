import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_primitives.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_qr_band.dart';

/// Met le ticket d'annulation en **lignes de caractères** (continuité des
/// tickets RC, lot B).
///
/// Même pivot que le ticket de caisse (`TicketTextLayout`) : un modèle, des
/// lignes, deux renderers — `EscPosTicketRenderer.renderRichLines` et
/// `PdfTicketRenderer.renderRichLines` les consomment telles quelles, sur les
/// mêmes 48 colonnes. Un fichier à part : le gabarit de caisse est déjà long, et
/// les deux papiers ne partagent que l'en-tête de l'école.
///
/// Le papier se range dans la pile À LA PLACE du ticket qu'il annule : il se lit
/// donc d'abord par son numéro, puis par la mention qui dit qu'il ne vaut plus.
abstract final class TicketCancellationLayout {
  /// Le ticket en texte nu — la forme qui se compare entre les deux sorties.
  static List<String> render(
    TicketCancellationModel model, {
    int columns = TicketTextLayout.defaultColumns,
  }) => [for (final line in renderRich(model, columns: columns)) line.text];

  static List<TicketLine> renderRich(
    TicketCancellationModel model, {
    int columns = TicketTextLayout.defaultColumns,
  }) {
    final width = columns < 24 ? 24 : columns;
    final labels = model.labels;
    final lines = <String>[];
    final bold = <int>{};

    void emphasised(void Function() build) {
      final from = lines.length;
      build();
      for (var i = from; i < lines.length; i++) {
        bold.add(i);
      }
    }

    /// Ligne d'en-tête nommée, escamotée quand elle est vide ; libellé au-dessus
    /// quand les deux ne tiennent pas ensemble (cf. `TicketTextLayout`).
    void centeredOptional(String label, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      final oneLine = TicketCharset.printable('$label $trimmed');
      if (oneLine.length <= width) {
        lines.addAll(TicketTextPrimitives.centered(oneLine, width));
        return;
      }
      lines.addAll(TicketTextPrimitives.centered(label, width));
      lines.addAll(TicketTextPrimitives.centered(trimmed, width));
    }

    final rule = TicketTextPrimitives.rule(width);

    // ── L'établissement : le même en-tête que le ticket de caisse.
    emphasised(
      () => lines.addAll(
        TicketTextPrimitives.centered(model.schoolName.toUpperCase(), width),
      ),
    );
    lines.addAll(
      TicketTextPrimitives.centered(model.schoolAddress ?? '', width),
    );
    lines.addAll(
      TicketTextPrimitives.centered(model.schoolLocality ?? '', width),
    );
    lines.addAll(TicketTextPrimitives.centered(model.schoolEmail ?? '', width));
    centeredOptional(labels.schoolPhoneLabel, model.schoolPhone);
    centeredOptional(labels.tillPhoneLabel, model.schoolTillPhone);
    lines.add(rule);

    // ── La nature de la pièce, puis le numéro qu'elle annule : c'est par lui
    // que le promoteur range son papier.
    emphasised(
      () => lines.addAll(
        TicketTextPrimitives.centered(labels.title.toUpperCase(), width),
      ),
    );
    lines.add(rule);
    emphasised(() {
      lines.addAll(
        TicketTextPrimitives.centered(
          '${labels.receiptLabel} ${model.receiptNumber}',
          width,
        ),
      );
      lines.add(TicketTextPrimitives.banner(labels.cancelledMark, width));
    });
    TicketTextPrimitives.addPair(
      lines,
      '${labels.issuedAtLabel} '
      '${TicketTextPrimitives.formatDate(model.originalPaidAt)}',
      TicketTextPrimitives.formatTime(model.originalPaidAt),
      width,
    );
    lines.add(rule);

    // ── L'élève et l'argent.
    lines.addAll(
      TicketTextPrimitives.wrapped(model.studentFullName.toUpperCase(), width),
    );
    TicketTextPrimitives.addOptional(
      lines,
      labels.classroomLabel,
      model.classroomName,
      width,
    );
    var first = true;
    for (final amount in model.amount.entries) {
      TicketTextPrimitives.addPair(
        lines,
        first ? labels.amountLabel : '',
        TicketTextLayout.formatAmount(amount.amountInCents, amount.currency),
        width,
      );
      first = false;
    }
    lines.add(rule);

    // ── L'annulation : quand, pourquoi, l'argent, qui.
    TicketTextPrimitives.addPair(
      lines,
      '${labels.cancelledAtLabel} '
      '${TicketTextPrimitives.formatDate(model.cancelledAt)}',
      TicketTextPrimitives.formatTime(model.cancelledAt),
      width,
    );
    TicketTextPrimitives.addOptional(
      lines,
      labels.reasonLabel,
      model.reason,
      width,
    );
    TicketTextPrimitives.addOptional(
      lines,
      labels.detailLabel,
      model.reasonDetail,
      width,
    );
    TicketTextPrimitives.addOptional(
      lines,
      labels.cashReturnedLabel,
      model.cashMoved ? labels.yes : labels.no,
      width,
    );
    TicketTextPrimitives.addOptional(
      lines,
      labels.cancelledByLabel,
      model.cancelledByName,
      width,
    );
    lines.add(rule);

    // ── Le QR du reçu annulé : scanné, il dit « annulé ». Le ticket d'une
    // annulation n'existe que pour un reçu scellé, donc aucune garde de
    // provisoire ici.
    final verificationUrl = model.verificationUrl;
    int? qrAt;
    if (verificationUrl != null &&
        TicketQrBand.fits(verificationUrl, columns: width)) {
      lines.addAll(
        TicketTextPrimitives.centeredWrapped(labels.verificationNotice, width),
      );
      qrAt = lines.length;
      lines.add('');
    }

    return [
      for (var i = 0; i < lines.length; i++)
        if (i == qrAt)
          TicketLine.qr(verificationUrl!)
        else
          TicketLine(lines[i], bold: bold.contains(i)),
    ];
  }
}
