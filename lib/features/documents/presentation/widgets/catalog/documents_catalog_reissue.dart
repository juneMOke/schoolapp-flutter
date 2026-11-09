import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_reason_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/receipt_emission_day.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/documents_local_dossier_cubit.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/models/documents_catalog_action.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_labels.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Longueur maximale du motif, celle du contrat (`reason`, 500 caractères).
const int kDocumentsReissueReasonMaxLength = 500;

/// « Réémettre corrigée » : le geste second d'une ligne AI, NP ou FI.
///
/// La ligne ne le pose que si une pièce est réémissible (en ligne, pièce
/// identifiée, AI, NP ou FI). Masqué sans `editique.cancel` — la route annule
/// la pièce en vigueur — et alors **sans aucun blanc** : l'écart [gap] au-dessus
/// du bouton est dans la garde. Gelé en session lecture seule, comme toute
/// production. [busy] vient de la ligne, qui suit déjà l'état de son bloc.
class DocumentsCatalogReissueButton extends StatelessWidget {
  final bool busy;
  final bool gap;
  final VoidCallback onPressed;

  const DocumentsCatalogReissueButton({
    super.key,
    required this.busy,
    required this.onPressed,
    this.gap = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate(
      requires: const [Perm.editiqueCancel],
      child: Padding(
        padding: EdgeInsets.only(top: gap ? AppDimensions.spacingS : 0),
        child: SessionWriteGate(
          child: EteeloButton.ghost(
            label: l10n.documentsReissueAction,
            icon: Icons.restart_alt_rounded,
            onPressed: busy ? null : onPressed,
            fullWidth: false,
          ),
        ),
      ),
    );
  }
}

/// Vrai quand la pièce rendue par une réémission n'est **pas** neuve : le
/// serveur a rendu une remplaçante déjà scellée, telle quelle.
///
/// C'est le cas quand la pièce envoyée était déjà remplacée ailleurs — une
/// autre tablette l'a réémise avant que celle-ci ne l'apprenne. La route est
/// rejouable : elle n'annule pas deux fois et ressert la pièce en vigueur, avec
/// le même 200 qu'une vraie réémission. Seul le jour d'émission la trahit — une
/// pièce composée aujourd'hui porte le jour de l'école, [today]. Une
/// réémission faite plus tôt le même jour reste indiscernable.
@visibleForTesting
bool isPriorReplacement(
  EditiqueDocument document, {
  required String sentDocumentId,
  required String today,
}) {
  if (document.documentId == sentDocumentId) return true;
  final emittedOn = document.emittedOn;
  return emittedOn != null && emittedOn.compareTo(today) < 0;
}

/// Demande le motif, réémet, montre la remplaçante, puis relit le dossier
/// local : la pièce remplacée y est désormais annulée, la remplaçante en
/// vigueur, et la ligne doit le dire sans attendre le pull.
///
/// La demande part **avant** la visionneuse — le bouton de la ligne dit
/// l'attente — pour qu'une pièce déjà remplacée ailleurs ne soit jamais
/// présentée comme la pièce corrigée : la tablette le dit, et propose de
/// réémettre celle-là, une fois.
Future<void> runDocumentsCatalogReissue(
  BuildContext context, {
  required EditiqueDocumentType type,
  required DocumentsCatalogAction action,
  required DocumentsCatalogIntent intent,
  required EditiqueDocumentBloc bloc,
  DateTime Function() now = DateTime.now,
}) async {
  var documentId = action.reissuablePiece?.documentId;
  if (documentId == null) return;

  final l10n = AppLocalizations.of(context)!;
  final title = DocumentsCatalogLabels.titleOf(l10n, type);
  final reason = await EteeloReasonDialog.show(
    context,
    EteeloReasonDialog(
      title: l10n.documentsReissueTitle(title),
      confirmLabel: l10n.documentsReissueConfirm,
      cancelLabel: l10n.documentsConfirmGenerateCancel,
      fieldLabel: l10n.documentsReissueReasonLabel,
      requiredError: l10n.documentsReissueReasonRequired,
      hint: l10n.documentsReissueReasonHint,
      helper: l10n.documentsReissueHelper,
      destructive: true,
      maxLength: kDocumentsReissueReasonMaxLength,
    ),
  );
  if (reason == null || reason.isEmpty || !context.mounted) return;

  final dossier = context.read<DocumentsLocalDossierCubit>();
  final today = DateOnlyJsonHelper.toJson(now());
  var askedAgain = false;
  while (true) {
    final outcome = await _reissue(
      bloc,
      EditiqueDocumentReissueRequested(
        type: type,
        documentId: documentId!,
        reason: reason,
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
      ),
    );
    if (outcome == null || !context.mounted) return;
    final returned = outcome.document;
    final returnedId = returned?.documentId;
    if (askedAgain ||
        returned == null ||
        returnedId == null ||
        !isPriorReplacement(
          returned,
          sentDocumentId: documentId,
          today: today,
        )) {
      break;
    }
    askedAgain = true;
    final again = await showAppConfirmationDialog(
      context: context,
      title: l10n.documentsReissuePriorTitle,
      message: l10n.documentsReissuePriorMessage(
        _day(context, returned.emittedOn) ?? returned.emittedOn ?? '',
      ),
      confirmLabel: l10n.documentsReissuePriorConfirm,
      cancelLabel: l10n.documentsReissuePriorShow,
      headerIcon: Icons.history_rounded,
      confirmIcon: Icons.restart_alt_rounded,
    );
    if (!context.mounted) return;
    if (!again) break;
    documentId = returnedId;
  }

  await showEditiqueReissueDialog(
    context,
    type: type,
    title: title,
    documentId: documentId,
    reason: reason,
    studentId: intent.studentId,
    academicYearId: intent.academicYearId,
    bloc: bloc,
    dispatchOnOpen: false,
  );
  // Relue même après un échec : une réponse perdue en route a pu laisser la
  // pièce remplacée côté serveur, et le delta l'aura peut-être déjà dit.
  await dossier.load(
    intent.enrollmentId,
    studentId: intent.studentId,
    academicYearId: intent.academicYearId,
  );
}

/// Envoie [request] et attend son issue, `null` si rien n'a pu partir (une
/// demande déjà en vol, ou la ligne fermée entre-temps).
Future<EditiqueDocumentState?> _reissue(
  EditiqueDocumentBloc bloc,
  EditiqueDocumentReissueRequested request,
) async {
  if (bloc.isClosed || bloc.state.status == EditiqueDocumentStatus.loading) {
    return null;
  }
  final settled = bloc.stream.firstWhere(
    (s) =>
        s.status == EditiqueDocumentStatus.success ||
        s.status == EditiqueDocumentStatus.failure,
  );
  bloc.add(request);
  try {
    return await settled;
  } on StateError {
    return null;
  }
}

String? _day(BuildContext context, String? emittedOn) {
  final day = ReceiptEmissionDay.toDate(emittedOn);
  return day == null
      ? null
      : MaterialLocalizations.of(context).formatMediumDate(day);
}
