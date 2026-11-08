import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_reason_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
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
/// Absent quand rien n'est réémissible (hors ligne, pièce connue par son seul
/// numéro, autre type) et masqué sans `editique.cancel` — la route annule la
/// pièce en vigueur. Gelé en session lecture seule, comme toute production.
class DocumentsCatalogReissueButton extends StatelessWidget {
  final DocumentsCatalogAction action;
  final VoidCallback onPressed;

  const DocumentsCatalogReissueButton({
    super.key,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (action.reissuablePiece == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EditiqueDocumentBloc, EditiqueDocumentState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final isBusy = state.status == EditiqueDocumentStatus.loading;
        return PermissionGate(
          requires: const [Perm.editiqueCancel],
          child: SessionWriteGate(
            child: EteeloButton.ghost(
              label: l10n.documentsReissueAction,
              icon: Icons.restart_alt_rounded,
              onPressed: isBusy ? null : onPressed,
              fullWidth: false,
            ),
          ),
        );
      },
    );
  }
}

/// Demande le motif, réémet, montre la remplaçante, puis relit le dossier
/// local : la pièce remplacée y est désormais annulée, la remplaçante en
/// vigueur, et la ligne doit le dire sans attendre le pull.
Future<void> runDocumentsCatalogReissue(
  BuildContext context, {
  required EditiqueDocumentType type,
  required DocumentsCatalogAction action,
  required DocumentsCatalogIntent intent,
  required EditiqueDocumentBloc bloc,
}) async {
  final piece = action.reissuablePiece;
  final documentId = piece?.documentId;
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
  await showEditiqueReissueDialog(
    context,
    type: type,
    title: title,
    documentId: documentId,
    reason: reason,
    studentId: intent.studentId,
    academicYearId: intent.academicYearId,
    bloc: bloc,
  );
  // Relue même après un échec : une réponse perdue en route a pu laisser la
  // pièce remplacée côté serveur, et le delta l'aura peut-être déjà dit.
  await dossier.load(
    intent.enrollmentId,
    studentId: intent.studentId,
    academicYearId: intent.academicYearId,
  );
}
