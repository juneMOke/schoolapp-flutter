import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La bulle du commentaire d'une note : pleine quand un commentaire existe.
/// Sans note saisie, elle est inerte — le commentaire voyage avec la note.
class NoteCommentaireButton extends StatelessWidget {
  final NoteEleve student;
  final bool enabled;
  final VoidCallback onPressed;

  const NoteCommentaireButton({
    super.key,
    required this.student,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final has = student.commentaire != null;
    final usable = enabled && student.statut != null;
    return IconButton(
      tooltip: !usable && student.statut == null
          ? l10n.noteCommentaireNeedsNote
          : has
          ? l10n.noteCommentaireEdit
          : l10n.noteCommentaireAdd,
      onPressed: usable ? onPressed : null,
      icon: Icon(
        has ? Icons.chat_bubble : Icons.chat_bubble_outline,
        size: AppDimensions.sujetIconSize,
        color: has ? AppColors.bleuArdoise : AppColors.textMuted,
      ),
    );
  }
}
