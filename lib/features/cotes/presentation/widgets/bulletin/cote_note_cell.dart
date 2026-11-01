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
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une cellule modifiable. Son texte vit dans son contrôleur : il ne suit l'état
/// que quand la cellule n'a pas le focus, sinon le curseur sauterait.
class CoteNoteCell extends StatefulWidget {
  final CoteCours cours;
  final CoteColumn column;
  final CoteFocusRegistry registry;
  final double height;
  final String columnLabel;

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
  });

  @override
  State<CoteNoteCell> createState() => _CoteNoteCellState();
}

class _CoteNoteCellState extends State<CoteNoteCell> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  late final CoteCellKey _key;

  /// Ce que la cellule portait en propre à l'arrivée du focus : Échap y revient.
  String _rawAtFocus = '';

  @override
  void initState() {
    super.initState();
    _key = widget.registry.keyOf(widget.cours, widget.column);
    _focusNode = widget.registry.nodeFor(widget.cours, widget.column)
      ..onKeyEvent = _onKey
      ..addListener(_onFocusChanged);
    _controller.text = _textOf(_cell(context.read<CoteSaisieBloc>().state));
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..onKeyEvent = null;
    _controller.dispose();
    super.dispose();
  }

  CoteCell? _cell(CoteSaisieState state) => state is CoteSaisieReady
      ? state.cells.cell(_key.studentId, _key.coursId, _key.colonneId)
      : null;

  String _textOf(CoteCell? cell) {
    if (cell == null) return '';
    final raw = cell.invalidRaw;
    if (raw != null) return raw;
    final value = cell.displayedValue;
    return value == null ? '' : formatCote(value);
  }

  void _onFocusChanged() {
    final cell = _cell(context.read<CoteSaisieBloc>().state);
    if (_focusNode.hasFocus) {
      _rawAtFocus = cell == null || cell.isCalculated ? '' : _textOf(cell);
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _controller.text = _textOf(cell);
    }
    setState(() {});
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
      _controller.text = _rawAtFocus;
      _edited(_rawAtFocus);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _edited(String raw) =>
      context.read<CoteSaisieBloc>().add(CoteCellEdited(_key, raw));

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
    final look = _CellLook.of(
      cell: cell,
      column: widget.column,
      focused: _focusNode.hasFocus,
      changed: changed,
      empty: _controller.text.isEmpty,
    );
    final max = widget.column.maxFor(widget.cours);
    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        LengthLimitingTextInputFormatter(5),
      ],
      style: AppTypography.bodyLarge.copyWith(
        color: look.ink,
        fontWeight: look.dashed ? FontWeight.w500 : FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: '—',
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
      onChanged: _edited,
      onEditingComplete: () {},
      onSubmitted: (_) {
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
            : Border.all(color: look.border, width: look.borderWidth),
        boxShadow: _focusNode.hasFocus
            ? const [
                BoxShadow(
                  color: AppColors.stateFocus,
                  spreadRadius: AppDimensions.coteFocusHalo,
                ),
              ]
            : null,
      ),
      child: look.dashed
          ? CustomPaint(
              painter: DashedRRectPainter(
                color: look.border,
                borderRadius: AppRadius.brSm,
                strokeWidth: 1,
                dash: 4,
                gap: 3,
              ),
              child: Center(child: field),
            )
          : field,
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
      child: hint == null ? body : Tooltip(message: hint, child: body),
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

/// Six apparences, la légende les reprend.
class _CellLook {
  final Color surface;
  final Color border;
  final Color ink;
  final double borderWidth;
  final bool dashed;

  const _CellLook({
    required this.surface,
    required this.border,
    required this.ink,
    this.borderWidth = 1,
    this.dashed = false,
  });

  factory _CellLook.of({
    required CoteCell? cell,
    required CoteColumn column,
    required bool focused,
    required bool changed,
    required bool empty,
  }) {
    final exam = column.isExamen;
    if (cell?.isInvalid ?? false) {
      return const _CellLook(
        surface: AppColors.coteInvalidSurface,
        border: AppColors.error,
        ink: AppColors.error,
        borderWidth: 1.5,
      );
    }
    if (focused) {
      return const _CellLook(
        surface: AppColors.surfaceRaised,
        border: AppColors.bleuArdoise,
        ink: AppColors.bleuProfond,
        borderWidth: 1.5,
      );
    }
    if (changed) {
      return const _CellLook(
        surface: AppColors.coteChangedSurface,
        border: AppColors.warning,
        ink: AppColors.bleuProfond,
        borderWidth: 1.5,
      );
    }
    if (empty) {
      return const _CellLook(
        surface: AppColors.coteEmptySurface,
        border: AppColors.coteEmptyBorder,
        ink: AppColors.textMuted,
        dashed: true,
      );
    }
    final surface = exam ? AppColors.coteExamSurface : AppColors.surfaceRaised;
    final border = exam ? AppColors.coteExamBorder : AppColors.coteCellBorder;
    if (cell?.isCalculated ?? false) {
      return _CellLook(
        surface: surface,
        border: border,
        ink: AppColors.textSecondary,
        dashed: true,
      );
    }
    return _CellLook(
      surface: surface,
      border: border,
      ink: exam ? AppColors.coteExamInk : AppColors.bleuProfond,
    );
  }
}
