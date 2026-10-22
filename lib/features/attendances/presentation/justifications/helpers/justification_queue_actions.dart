import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/attachments/attachment_document.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_reason_dialog.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/helpers/justification_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mot de l'école au parent : 500 caractères au plus (contrat V182).
const int kJustificationDecisionNoteMaxLength = 500;

/// Les gestes de la file, orchestrés : la modale, l'écriture, l'accusé.
class JustificationQueueActions {
  final BuildContext context;

  const JustificationQueueActions(this.context);

  JustificationQueueCubit get _cubit => context.read<JustificationQueueCubit>();

  Future<void> accept(AttendanceJustification justification) =>
      _decide(justification, JustificationDecision.accept);

  /// Le refus porte toujours un mot : c'est lui que le parent lira.
  Future<void> reject(AttendanceJustification justification) =>
      _decide(justification, JustificationDecision.reject);

  Future<void> _decide(
    AttendanceJustification justification,
    JustificationDecision decision,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = _cubit;
    final accepting = decision == JustificationDecision.accept;
    final note = await EteeloReasonDialog.show(
      context,
      EteeloReasonDialog(
        title: accepting
            ? l10n.justificationAcceptTitle
            : l10n.justificationRejectTitle,
        hint: l10n.justificationDecisionHint(
          JustificationLabels.student(l10n, justification),
          PresenceLabels.longDay(
            MaterialLocalizations.of(context),
            justification.attendanceDate,
          ),
        ),
        confirmLabel: accepting
            ? l10n.justificationAccept
            : l10n.justificationReject,
        cancelLabel: l10n.justificationCancel,
        fieldLabel: l10n.justificationNoteLabel,
        requiredError: l10n.justificationNoteRequired,
        helper: l10n.justificationNoteHelper,
        isRequired: !accepting,
        destructive: !accepting,
        maxLength: kJustificationDecisionNoteMaxLength,
      ),
    );
    if (note == null || !context.mounted) return;
    final result = await cubit.decide(justification, decision, note: note);
    if (!context.mounted) return;
    result.fold(
      (failure) => AppSnackBar.showError(
        context,
        failure is ConflictFailure
            ? l10n.justificationDecisionConflict
            : l10n.justificationDecisionFailed,
      ),
      (_) {
        _notifyLocalWrite();
        AppSnackBar.showSuccess(context, l10n.justificationDecisionSaved);
      },
    );
  }

  /// Télécharge la pièce (ou la relit du dossier temporaire) et l'ouvre dans
  /// la visionneuse, sans partage ni impression : c'est souvent le
  /// certificat médical d'un mineur.
  Future<void> openAttachment(AttendanceJustification justification) async {
    final l10n = AppLocalizations.of(context)!;
    final ref = justification.attachment;
    if (ref == null) return;
    // Rien à télécharger qu'on ne saurait pas montrer.
    if (!ref.isViewable) {
      AppSnackBar.showError(context, l10n.justificationAttachmentNotViewable);
      return;
    }
    final result = await _cubit.attachment(justification);
    if (!context.mounted) return;
    final bytes = result.fold((failure) {
      AppSnackBar.showError(
        context,
        failure is NetworkFailure
            ? l10n.justificationAttachmentOffline
            : l10n.justificationAttachmentUnavailable,
      );
      return null;
    }, (bytes) => bytes);
    if (bytes == null) return;
    final document = await AttachmentDocument.compose([
      (ref: ref, bytes: bytes),
    ], fileName: ref.name);
    if (!context.mounted) return;
    if (document == null) {
      AppSnackBar.showError(context, l10n.justificationAttachmentNotViewable);
      return;
    }
    await showEteeloDocumentViewer(
      context,
      title: l10n.justificationAttachmentTitle(
        JustificationLabels.student(l10n, justification),
      ),
      document: document,
      canShare: false,
      canPrint: false,
    );
  }

  void _notifyLocalWrite() {
    try {
      context.read<SyncStatusCubit>().notifyLocalWrite();
    } on ProviderNotFoundException {
      // Aucune pastille montée : le battement poussera.
    }
  }
}
