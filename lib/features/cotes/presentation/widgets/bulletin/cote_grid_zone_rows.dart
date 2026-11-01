import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';

/// Se reconstruit quand les chiffres de cet élève bougent, jamais pour un autre.
class CoteStudentBuilder extends StatelessWidget {
  final String studentId;
  final Widget Function(BuildContext, CoteSaisieReady) builder;

  const CoteStudentBuilder({
    super.key,
    required this.studentId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
      buildWhen: (previous, current) =>
          current is CoteSaisieReady &&
          (previous is! CoteSaisieReady ||
              previous.calcs[studentId] != current.calcs[studentId]),
      builder: (context, state) => state is CoteSaisieReady
          ? builder(context, state)
          : const SizedBox.shrink(),
    );
  }
}

/// Le filet gauche d'une colonne : plus marqué au début de chaque groupe.
Border coteColumnEdge(CoteGridColumn column, CoteGridContext grid) {
  final index = grid.gridColumns.indexOf(column);
  if (index == 0) return const Border();
  final startsGroup =
      grid.gridColumns[index - 1].source.periodeId != column.source.periodeId;
  return Border(
    left: BorderSide(
      color: startsGroup || column.isMax
          ? AppColors.borderStrong
          : AppColors.border,
      width: startsGroup ? 2 : 1,
    ),
  );
}

/// Le style des lignes de pied sombres.
TextStyle coteDarkRowStyle({bool strong = false}) =>
    AppTypography.bodySmall.copyWith(
      color: AppColors.textOnDark,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// Le style des maxima.
TextStyle coteMaximaStyle() => AppTypography.labelSmall.copyWith(
  color: AppColors.bleuArdoise,
  fontWeight: FontWeight.w800,
  fontFeatures: const [FontFeature.tabularFigures()],
);
