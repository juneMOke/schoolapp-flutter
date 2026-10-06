import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_sync_pill.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Les notes de séance : « + Ajouter une note » ouvre une saisie en ligne ;
/// la note s'insère en tête, datée du jour. Supprimer se défait pendant
/// quelques secondes (le toast porte « Annuler »).
class ChapitreNotesSection extends StatefulWidget {
  final List<ChapitreNote> notes;

  /// Rend `true` si la note est gardée ; un échec laisse le texte saisi.
  final Future<bool> Function(String texte) onAdd;
  final ValueChanged<String> onDelete;

  /// Lu en ligne : ni ajout ni suppression.
  final bool readOnly;

  const ChapitreNotesSection({
    super.key,
    required this.notes,
    required this.onAdd,
    required this.onDelete,
    this.readOnly = false,
  });

  @override
  State<ChapitreNotesSection> createState() => _ChapitreNotesSectionState();
}

class _ChapitreNotesSectionState extends State<ChapitreNotesSection> {
  final _draft = TextEditingController();
  bool _writing = false;
  bool _saving = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  /// Un seul envoi à la fois : un double appui ne crée pas deux notes.
  Future<void> _save() async {
    final texte = _draft.text.trim();
    if (texte.isEmpty || _saving) return;
    setState(() => _saving = true);
    final kept = await widget.onAdd(texte);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (kept) {
        _draft.clear();
        _writing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notes = widget.notes;
    return ChapitreSection(
      icon: Icons.sticky_note_2_outlined,
      title: l10n.chapitreSectionNotes,
      count: notes.length,
      action: _writing || widget.readOnly
          ? null
          : ProgrammeWriteGate(
              child: TextButton.icon(
                onPressed: () => setState(() => _writing = true),
                icon: const Icon(
                  Icons.add_rounded,
                  size: ProgrammeLayout.iconMedium,
                ),
                label: Text(l10n.chapitreNoteAdd),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_writing) _composer(l10n),
          if (notes.isEmpty && !_writing)
            ChapitreSectionEmpty(l10n.chapitreNotesEmpty),
          for (var i = 0; i < notes.length; i++) ...[
            if (i > 0 || _writing)
              const Divider(height: 1, color: AppColors.border),
            _NoteTile(
              key: ValueKey<String>(notes[i].id),
              note: notes[i],
              onDelete: widget.readOnly
                  ? null
                  : () => widget.onDelete(notes[i].id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _composer(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloTextInput(
          controller: _draft,
          label: l10n.chapitreNoteAdd,
          hideLabel: true,
          placeholder: l10n.chapitreNoteHint,
          keyboardType: EteeloTextInputType.multiline,
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          children: [
            EteeloButton.secondary(
              label: l10n.cancel,
              onPressed: () => setState(() => _writing = false),
              fullWidth: false,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _draft,
              builder: (context, value, _) => EteeloButton.primary(
                label: l10n.chapitreFormSave,
                icon: Icons.check_rounded,
                onPressed: value.text.trim().isEmpty || _saving ? null : _save,
                fullWidth: false,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NoteTile extends StatelessWidget {
  final ChapitreNote note;
  final VoidCallback? onDelete;

  const _NoteTile({super.key, required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.chapitreNoteDate(note.ecriteLe.toLocal()),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    ProgrammeSyncPill(state: note.syncState),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  note.texte,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            ProgrammeWriteGate(
              child: IconButton(
                tooltip: l10n.chapitreNoteDelete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }
}
