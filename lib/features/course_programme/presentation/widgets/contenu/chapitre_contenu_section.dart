import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/services/contenu_limits.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/contenu_draft.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/common/programme_write_gate.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/contenu/bloc_edition.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/contenu/bloc_lecture.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/contenu/contenu_add_bar.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/detail/chapitre_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Enregistre les blocs ; [announce] : dire « Contenu enregistré ».
typedef ContenuSaver =
    Future<bool> Function(List<ChapitreBloc> blocs, {bool announce});

/// Le contenu rédigé d'un chapitre (spec §8), en deux modes : la lecture
/// (rendu document, ligne limitée) et l'édition (cartes de bloc
/// réordonnables). Pendant la frappe, le brouillon reste en mémoire ; il part
/// au « Terminer » ou après [ContenuDraft.autosaveDelay] sans frappe. Un bloc
/// vide n'est jamais gardé ; au-delà du plafond, rien ne part.
class ChapitreContenuSection extends StatefulWidget {
  final List<ChapitreBloc> blocs;
  final bool canWrite;
  final String Function() newId;
  final ContenuSaver onSave;

  const ChapitreContenuSection({
    super.key,
    required this.blocs,
    required this.canWrite,
    required this.newId,
    required this.onSave,
  });

  /// La ligne de lecture : environ 68 caractères.

  @override
  State<ChapitreContenuSection> createState() => _ChapitreContenuSectionState();
}

/// Un bouton posé dans une rangée : sans taille minimale explicite, le thème
/// lui impose une largeur infinie.
const Size _inlineButtonSize = Size(0, AppDimensions.minTouchTarget);

class _ChapitreContenuSectionState extends State<ChapitreContenuSection> {
  ContenuDraft? _draft;
  Timer? _autosave;

  bool get _editing => _draft != null;

  void _startEditing({bool seed = false}) {
    final draft = ContenuDraft(widget.blocs, newId: widget.newId);
    if (seed) draft.seed();
    draft.addListener(_onDraftChanged);
    setState(() => _draft = draft);
  }

  void _onDraftChanged() {
    setState(() {});
    _autosave?.cancel();
    _autosave = Timer(ContenuDraft.autosaveDelay, _saveSilently);
  }

  void _saveSilently() {
    final draft = _draft;
    if (draft == null || draft.tooHeavy) return;
    unawaited(widget.onSave(draft.blocs, announce: false));
  }

  Future<void> _finish() async {
    final draft = _draft;
    if (draft == null || draft.tooHeavy) return;
    _autosave?.cancel();
    final blocs = draft.blocs;
    setState(() => _draft = null);
    draft.dispose();
    await widget.onSave(blocs);
  }

  @override
  void dispose() {
    _autosave?.cancel();
    final draft = _draft;
    if (draft != null) {
      // Quitter l'écran en cours de frappe garde ce qui a été écrit.
      if (!draft.tooHeavy) {
        unawaited(widget.onSave(draft.blocs, announce: false));
      }
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = _draft;
    return ChapitreSection(
      icon: Icons.article_outlined,
      title: l10n.chapitreSectionContenu,
      count: draft?.lines.length ?? widget.blocs.length,
      action: widget.canWrite ? _toggle(l10n) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: draft == null ? _reading(l10n) : _edition(l10n, draft),
      ),
    );
  }

  Widget _toggle(AppLocalizations l10n) => ProgrammeWriteGate(
    child: _editing
        ? FilledButton.icon(
            onPressed: _draft!.tooHeavy ? null : _finish,
            icon: const Icon(
              Icons.check_rounded,
              size: ProgrammeLayout.iconMedium,
            ),
            label: Text(l10n.contenuDone),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bleuArdoise,
              minimumSize: _inlineButtonSize,
            ),
          )
        : OutlinedButton.icon(
            onPressed: _startEditing,
            icon: const Icon(
              Icons.edit_outlined,
              size: ProgrammeLayout.iconMedium,
            ),
            label: Text(l10n.contenuWrite),
            style: OutlinedButton.styleFrom(minimumSize: _inlineButtonSize),
          ),
  );

  Widget _reading(AppLocalizations l10n) {
    if (widget.blocs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.contenuEmpty,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          if (widget.canWrite) ...[
            const SizedBox(height: AppSpacing.md),
            ProgrammeWriteGate(
              child: EteeloButton.secondary(
                label: l10n.contenuStart,
                icon: Icons.edit_outlined,
                onPressed: () => _startEditing(seed: true),
                fullWidth: false,
              ),
            ),
          ],
        ],
      );
    }
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ProgrammeLayout.readingMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.blocs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: BlocLecture(bloc: widget.blocs[i], first: i == 0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _edition(AppLocalizations l10n, ContenuDraft draft) {
    final lines = draft.lines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            key: ValueKey<String>(lines[i].id),
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: BlocEdition(
              line: lines[i],
              onMoveUp: i == 0 ? null : () => draft.move(lines[i], -1),
              onMoveDown: i == lines.length - 1
                  ? null
                  : () => draft.move(lines[i], 1),
              onDelete: () => draft.remove(lines[i]),
            ),
          ),
        if (!draft.canAdd)
          _Warning(l10n.contenuTooManyBlocs(ContenuLimits.maxBlocs)),
        if (draft.tooHeavy) _Warning(l10n.contenuTooHeavy),
        ContenuAddBar(onAdd: draft.canAdd ? draft.add : null),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  final String message;

  const _Warning(this.message);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: ProgrammeLayout.iconSmall,
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}
