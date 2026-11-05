import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La surface de la bande d'aide : la case nommée, puis son aide, lues dans
/// l'état. Sans aide, une ligne vide : la bande garde sa hauteur d'une case à
/// l'autre.
class CoteGridHintPanel extends StatelessWidget {
  final CoteClasse classe;
  final String studentId;
  final CoteCours cours;
  final CoteColumn column;

  const CoteGridHintPanel({
    super.key,
    required this.classe,
    required this.studentId,
    required this.cours,
    required this.column,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppElevation.shadowCard,
      ),
      // Une clé par case : le sélecteur repart de l'état courant, pas de
      // celui de la case précédente.
      child: BlocSelector<CoteSaisieBloc, CoteSaisieState, CoteCell?>(
        key: ValueKey('${cours.coursId}|${column.id}'),
        selector: (state) => state is CoteSaisieReady
            ? state.cells.cell(studentId, cours.coursId, column.id)
            : null,
        builder: (context, cell) {
          final l10n = AppLocalizations.of(context)!;
          final hint = CoteLabels.cellHint(l10n, cell, column.maxFor(cours));
          return _HintText(
            subject: hint == null
                ? null
                : l10n.coteHintBandSubject(
                    cours.branche,
                    CoteLabels.columnLong(l10n, classe, column),
                  ),
            hint: hint,
          );
        },
      ),
    );
  }
}

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
