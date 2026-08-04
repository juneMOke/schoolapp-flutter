import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Compose puis remet à l'impression le reçu provisoire d'un encaissement.
///
/// C'est l'exigence terrain irréductible de l'ADR-012 : un parent qui verse des
/// espèces repart **avec un papier**, coupure réseau ou non. Rien ici ne touche
/// le réseau.
///
/// ⚠️ La sortie passe par le spouleur système, qui applique le format papier
/// choisi par l'utilisateur : sur un poste sans imprimante thermique 80 mm, le
/// ticket sortira mis à l'échelle sur le format par défaut. La sortie ESC/POS
/// vers une imprimante appairée, elle, respectera la largeur — c'est un lot
/// plateforme distinct.
///
/// Renvoie `false` si rien n'a pu être produit ou remis au spouleur ; l'appelant
/// est responsable de le dire à l'utilisateur, jamais d'échouer en silence.
Future<bool> printProvisionalTicket(
  BuildContext context, {
  required String paymentId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final labels = provisionalTicketLabels(l10n);

  final built = await getIt<BuildProvisionalTicketUseCase>()(
    paymentId: paymentId,
    labels: labels,
  );

  return built.fold((_) async => false, (model) async {
    try {
      final bytes = await PdfTicketRenderer.render(model);
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: model.provisionalReference,
        format: PdfTicketRenderer.pageFormat,
      );
      return true;
    } catch (_) {
      // Canal de plateforme absent, service d'impression indisponible : la
      // pièce est intacte, seul le geste a échoué.
      return false;
    }
  });
}
