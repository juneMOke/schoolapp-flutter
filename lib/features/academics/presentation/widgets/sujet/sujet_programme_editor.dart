import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/fields/numbered_line_row.dart';
import 'package:school_app_flutter/core/components/labels/form_section_label.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Liste ordonnée « Au programme » (spec §4 bis) : ce que l'élève révise.
///
/// Entrée ajoute une ligne dessous ; Retour arrière sur une ligne vide la
/// supprime ; ✕ la retire. Les lignes vides partent telles quelles dans
/// [onChanged] — c'est l'enregistrement qui les écarte.
///
/// [onReprendreChapitres], s'il est fourni, s'affiche à droite du libellé
/// tant que la liste est vide : il remplit une ligne par chapitre coché.
/// Une liste imposée de l'extérieur ([lines] différent de la saisie) remplace
/// les lignes affichées.
class SujetProgrammeEditor extends StatefulWidget {
  final List<String> lines;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback? onReprendreChapitres;

  const SujetProgrammeEditor({
    super.key,
    required this.lines,
    required this.onChanged,
    this.onReprendreChapitres,
  });

  @override
  State<SujetProgrammeEditor> createState() => _SujetProgrammeEditorState();
}

class _ProgrammeLine {
  final int key;
  final TextEditingController controller;
  final FocusNode focusNode;

  _ProgrammeLine(this.key, String text)
    : controller = TextEditingController(text: text),
      focusNode = FocusNode();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _SujetProgrammeEditorState extends State<SujetProgrammeEditor> {
  final List<_ProgrammeLine> _lines = [];
  int _nextKey = 0;

  List<String> get _texts => [for (final l in _lines) l.controller.text];

  @override
  void initState() {
    super.initState();
    _reset(widget.lines);
  }

  @override
  void didUpdateWidget(SujetProgrammeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.lines, _texts)) {
      _reset(widget.lines);
    }
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _reset(List<String> texts) {
    for (final line in _lines) {
      line.dispose();
    }
    _lines
      ..clear()
      ..addAll([for (final t in texts) _newLine(t)]);
  }

  _ProgrammeLine _newLine(String text) {
    final line = _ProgrammeLine(_nextKey++, text);
    line.focusNode.onKeyEvent = (node, event) => _onKey(line, event);
    return line;
  }

  KeyEventResult _onKey(_ProgrammeLine line, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace ||
        line.controller.text.isNotEmpty) {
      return KeyEventResult.ignored;
    }
    final index = _lines.indexOf(line);
    _remove(line);
    if (index > 0) _lines[index - 1].focusNode.requestFocus();
    return KeyEventResult.handled;
  }

  void _insertAfter(int index) {
    final line = _newLine('');
    setState(() => _lines.insert(index + 1, line));
    _emit();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => line.focusNode.requestFocus(),
    );
  }

  void _remove(_ProgrammeLine line) {
    setState(() => _lines.remove(line));
    _emit();
    WidgetsBinding.instance.addPostFrameCallback((_) => line.dispose());
  }

  void _emit() => widget.onChanged(_texts);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reprendre = widget.onReprendreChapitres;
    final showReprendre =
        reprendre != null && _texts.every((t) => t.trim().isEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionLabel(
          label: l10n.sujetProgrammeLabel,
          optional: true,
          action: showReprendre
              ? TextButton(
                  onPressed: reprendre,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.bleuArdoise,
                  ),
                  child: Text(l10n.sujetProgrammeFromChapters),
                )
              : null,
        ),
        for (final (i, line) in _lines.indexed)
          Padding(
            key: ValueKey<int>(line.key),
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: NumberedLineRow(
              number: i + 1,
              controller: line.controller,
              focusNode: line.focusNode,
              badgeSize: AppDimensions.sujetNumberBadge,
              label: l10n.sujetProgrammeLine(i + 1),
              placeholder: l10n.sujetProgrammeHint,
              removeTooltip: l10n.sujetProgrammeRemove,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => _insertAfter(i),
              onRemove: () => _remove(line),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _insertAfter(_lines.length - 1),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.sujetProgrammeAdd),
            style: TextButton.styleFrom(foregroundColor: AppColors.bleuArdoise),
          ),
        ),
      ],
    );
  }
}
