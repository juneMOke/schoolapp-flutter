import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_reason_dialog.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_commentaire.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le commentaire d'une note : la modale, pré-remplie du commentaire actuel,
/// puis l'enregistrement par le BLoC de saisie. Vider le champ retire le
/// commentaire ; le laisser inchangé n'envoie rien.
Future<void> openNoteCommentaire(
  BuildContext context, {
  required String evaluationId,
  required NoteEleve student,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<SaisieNotesBloc>();
  final typed = await EteeloReasonDialog.show(
    context,
    EteeloReasonDialog(
      title: l10n.noteCommentaireTitle(student.firstName),
      confirmLabel: l10n.noteCommentaireSave,
      cancelLabel: l10n.noteCommentaireCancel,
      fieldLabel: l10n.noteCommentaireLabel,
      requiredError: '',
      helper: l10n.noteCommentaireHelper,
      isRequired: false,
      maxLength: NoteCommentaire.maxLength,
      initialText: student.commentaire,
    ),
  );
  if (typed == null) return;
  bloc.add(
    NoteCommentaireSaisi(
      evaluationId: evaluationId,
      studentId: student.studentId,
      typed: typed,
    ),
  );
}
