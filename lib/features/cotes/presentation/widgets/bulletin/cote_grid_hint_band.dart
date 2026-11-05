import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'aide de la case au focus, sous la grille : au tactile, l'appui long
/// sélectionne le texte avant que l'info-bulle ne s'ouvre. Elle ne fait que
/// lire — la case, sa frappe et son écriture ne la connaissent pas.
///
/// Toujours une ligne de haut, vide ou non : passer d'une case à l'autre ne
/// fait pas sauter la page. Hors de la sémantique : la case porte déjà son
/// aide au lecteur d'écran, la bande la redirait.
class CoteGridHintBand extends StatefulWidget {
  final CoteGridContext grid;

  const CoteGridHintBand({super.key, required this.grid});

  @override
  State<CoteGridHintBand> createState() => _CoteGridHintBandState();
}

class _CoteGridHintBandState extends State<CoteGridHintBand> {
  ({CoteCours cours, CoteColumn column})? _focused;

  @override
  void initState() {
    super.initState();
    _focused = widget.grid.registry.focusedCell;
    // Le focus primaire change hors construction : seule la bande se
    // reconstruit, jamais la grille.
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final focused = widget.grid.registry.focusedCell;
    if (focused == _focused) return;
    setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focused;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: focused == null
            ? const _HintText(subject: null, hint: null)
            // Une clé par case : le sélecteur repart de l'état courant, pas
            // de celui de la case précédente.
            : BlocSelector<CoteSaisieBloc, CoteSaisieState, CoteCell?>(
                key: ValueKey('${focused.cours.coursId}|${focused.column.id}'),
                selector: (state) => _cellOf(state, focused),
                builder: (context, cell) => _hint(context, focused, cell),
              ),
      ),
    );
  }

  CoteCell? _cellOf(
    CoteSaisieState state,
    ({CoteCours cours, CoteColumn column}) focused,
  ) => state is CoteSaisieReady
      ? state.cells.cell(
          widget.grid.studentId,
          focused.cours.coursId,
          focused.column.id,
        )
      : null;

  Widget _hint(
    BuildContext context,
    ({CoteCours cours, CoteColumn column}) focused,
    CoteCell? cell,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final hint = CoteLabels.cellHint(
      l10n,
      cell,
      focused.column.maxFor(focused.cours),
    );
    if (hint == null) return const _HintText(subject: null, hint: null);
    return _HintText(
      subject: l10n.coteHintBandSubject(
        focused.cours.branche,
        CoteLabels.columnLong(l10n, widget.grid.classe, focused.column),
      ),
      hint: hint,
    );
  }
}

/// Le texte de la bande : la case nommée, puis son aide. Vide, il garde la
/// hauteur d'une ligne.
class _HintText extends StatelessWidget {
  final String? subject;
  final String? hint;

  const _HintText({required this.subject, required this.hint});

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Icon(
            Icons.info_outline,
            size: AppDimensions.coteInlineIconSize,
            color: hint == null ? Colors.transparent : AppColors.textMutedAa,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (subject != null)
                  TextSpan(
                    text: subject,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                TextSpan(text: hint ?? ''),
              ],
            ),
            style: style,
          ),
        ),
      ],
    );
  }
}
