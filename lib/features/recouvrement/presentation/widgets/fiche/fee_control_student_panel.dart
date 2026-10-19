import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_student_sheet.dart';

/// L'aperçu d'un élève ancré à droite du tableau (grand écran).
///
/// Relu sur les résultats à chaque rendu : une nouvelle recherche qui ne
/// contient plus l'élève le referme, au lieu de montrer une ligne périmée.
class FeeControlStudentPanel extends StatelessWidget {
  final String studentId;
  final String academicYearId;
  final VoidCallback onClose;

  const FeeControlStudentPanel({
    super.key,
    required this.studentId,
    required this.academicYearId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeeControlBloc, FeeControlState>(
      builder: (context, state) {
        final bloc = context.read<FeeControlBloc>();
        final row = bloc.results
            .where((r) => r.studentId == studentId)
            .firstOrNull;
        if (row == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onClose());
          return const SizedBox.shrink();
        }
        return BlocBuilder<FeeControlSelectionCubit, FeeControlSelectionState>(
          builder: (context, selection) => FeeControlStudentSheet.docked(
            row: row,
            tariffs: state.tariffs,
            sectionTitles: context.watch<FeeSectionTitlesCubit>().state,
            rate: state.lastQuery?.rate,
            marked: selection.marked.contains(row.studentId),
            onToggleMark: () => toggleStudentMark(context, row),
            onOpenRecord: () =>
                openFinancialRecord(context, row, academicYearId),
            onClose: onClose,
          ),
        );
      },
    );
  }
}
