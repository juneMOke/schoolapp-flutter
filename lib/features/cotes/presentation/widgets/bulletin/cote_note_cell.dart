import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_cell_look.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une cellule modifiable. Son texte vit dans son contrôleur : il ne suit l'état
/// que quand la cellule n'a pas le focus, sinon le curseur sauterait.
class CoteNoteCell extends StatefulWidget {
  final CoteCours cours;
  final CoteColumn column;
  final CoteFocusRegistry registry;
  final double height;
  final String columnLabel;

  /// Beaucoup de colonnes : le texte se resserre pour tenir.
  final bool dense;

  /// Ce que fait Entrée : cours suivant, ou colonne suivante.
  final CoteMove enterMove;

  const CoteNoteCell({
    super.key,
    required this.cours,
    required this.column,
    required this.registry,
    required this.height,
    required this.columnLabel,
    required this.enterMove,
    this.dense = false,
  });

  @override
  State<CoteNoteCell> createState() => _CoteNoteCellState();
}

class _CoteNoteCellState extends State<CoteNoteCell> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  late final CoteCellKey _key;
  late final CoteSaisieBloc _bloc;

  /// La cellule à l'arrivée du focus : toute frappe se juge contre elle, et Échap
  /// y revient. Rien ne s'écrit avant de quitter la case.
  CoteCell? _base;
  bool _dirty = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CoteSaisieBloc>();
    _key = widget.registry.keyOf(widget.cours, widget.column);
    _focusNode = widget.registry.nodeFor(widget.cours, widget.column)
      ..onKeyEvent = _onKey
      ..addListener(_onFocusChanged);
    _controller.text = _textOf(_cell(_bloc.state));
  }

  @override
  void dispose() {
    _commit();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..onKeyEvent = null;
    _controller.dispose();
    super.dispose();
  }

  CoteCell? _cell(CoteSaisieState state) => state is CoteSaisieReady
      ? state.cells.cell(_key.studentId, _key.coursId, _key.colonneId)
      : null;

  CoteCell get _currentCell => _cell(_bloc.state) ?? CoteCell(key: _key);

  String _textOf(CoteCell? cell) {
    if (cell == null) return '';
    final raw = cell.invalidRaw;
    if (raw != null) return raw;
    final value = cell.displayedValue;
    return value == null ? '' : formatCote(value);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _base = _currentCell;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _commit();
      _controller.text = _textOf(_cell(_bloc.state));
    }
    setState(() {});
  }

  void _commit() {
    final base = _base;
    if (!_dirty || base == null || _bloc.isClosed) return;
    _dirty = false;
    _base = null;
    _bloc.add(CoteCellCommitted(_key, _controller.text, base));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.registry.move(_key, CoteMove.down);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.registry.move(_key, CoteMove.up);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _revert();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _revert() {
    final base = _base;
    if (!_dirty || base == null) return;
    _dirty = false;
    _bloc.add(CoteCellReverted(base));
    _controller.text = _textOf(base);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _typed(String raw) {
    _base ??= _currentCell;
    _dirty = true;
    _bloc.add(CoteCellTyped(_key, raw, _base!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<CoteSaisieBloc, CoteSaisieState>(
      listenWhen: (previous, current) => _cell(previous) != _cell(current),
      listener: (context, state) {
        if (_focusNode.hasFocus) return;
        final text = _textOf(_cell(state));
        if (text != _controller.text) _controller.text = text;
      },
      child: BlocSelector<CoteSaisieBloc, CoteSaisieState, (CoteCell?, bool)>(
        selector: (state) => (
          _cell(state),
          state is CoteSaisieReady && state.changedKeys.contains(_key),
        ),
        builder: (context, data) {
          final (cell, changed) = data;
          return _frame(l10n, cell, changed);
        },
      ),
    );
  }

  Widget _frame(AppLocalizations l10n, CoteCell? cell, bool changed) {
    final max = widget.column.maxFor(widget.cours);
    final value = cell?.displayedValue;
    final look = CoteCellLook.of(
      cell: cell,
      column: widget.column,
      focused: _focusNode.hasFocus,
      changed: changed,
      empty: _controller.text.isEmpty,
      scoreInk: value == null ? null : coteScoreInk(toCentis(value), max * 100),
    );
    // Le survol ne touche ni l'erreur ni le focus, qui parlent déjà.
    final edge = _hovered && !(cell?.isInvalid ?? false)
        ? AppColors.bleuArdoise
        : look.border;
    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        // « 139,25 » : les chiffres du maximum, la virgule, deux décimales.
        LengthLimitingTextInputFormatter('$max'.length + 3),
      ],
      style: (widget.dense ? AppTypography.bodyMedium : AppTypography.bodyLarge)
          .copyWith(
            color: look.ink,
            fontWeight: look.dashed ? FontWeight.w500 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: '—',
        hintStyle: TextStyle(color: AppColors.textMutedAa),
      ),
      onChanged: _typed,
      onEditingComplete: () {},
      onSubmitted: (_) {
        _commit();
        widget.registry.move(_key, widget.enterMove);
      },
    );
    final body = AnimatedContainer(
      duration: AppMotion.micro,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: look.surface,
        borderRadius: AppRadius.brSm,
        border: look.dashed
            ? null
            : Border.all(color: edge, width: look.borderWidth),
        boxShadow: _focusNode.hasFocus
            ? const [
                BoxShadow(
                  color: AppColors.stateFocus,
                  spreadRadius: AppDimensions.coteFocusHalo,
                ),
              ]
            : null,
      ),
      // Une seule forme d'arbre : remonter le champ au gain de focus lui ferait
      // perdre sa connexion au clavier.
      child: CustomPaint(
        painter: look.dashed
            ? DashedRRectPainter(
                color: edge,
                borderRadius: AppRadius.brSm,
                strokeWidth: 1,
                dash: 4,
                gap: 3,
              )
            : null,
        child: Center(child: field),
      ),
    );
    final hint = _hint(l10n, cell, max);
    return Semantics(
      label: l10n.coteCellSemantics(
        widget.cours.branche,
        widget.columnLabel,
        '$max',
      ),
      value: _controller.text,
      hint: hint,
      // Toujours visible et jamais vide : autrement, `Tooltip` rend son enfant
      // nu, et son apparition remonterait le champ en pleine frappe.
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(message: hint ?? widget.columnLabel, child: body),
      ),
    );
  }

  String? _hint(AppLocalizations l10n, CoteCell? cell, int max) {
    if (cell == null) return null;
    if (cell.invalidRaw != null) return l10n.coteCellInvalid('$max');
    if (cell.isRejected) {
      return CoteLabels.rejection(l10n, cell.rejectionReason);
    }
    if (cell.isCalculated) return l10n.coteCellCalculated;
    final calculee = cell.calculee;
    return calculee == null
        ? null
        : l10n.coteCellReplaces(formatCote(calculee));
  }
}
