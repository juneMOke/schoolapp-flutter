import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_query_phrase.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_data_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le résultat : son en-tête, qui **rejoue la requête**, et le tableau.
///
/// L'en-tête n'est pas décoratif. Il redit ce qui a été demandé — les frais, la
/// classe, la situation — et l'ordre dans lequel la liste sort. Sans lui, un
/// tableau trié du moins avancé au plus avancé passerait pour désordonné.
class FeeControlResultsSection extends StatelessWidget {
  final FeeControlState state;
  final ValueChanged<FeeControlRow> onViewRequested;
  final ValueChanged<FeeControlRow> onRowTapped;
  final String? emptyLabel;

  const FeeControlResultsSection({
    super.key,
    required this.state,
    required this.onViewRequested,
    required this.onRowTapped,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pageIds = [for (final row in state.rows) row.studentId];

    return BlocBuilder<FeeControlSelectionCubit, FeeControlSelectionState>(
      builder: (context, selection) {
        final allSelected =
            pageIds.isNotEmpty && pageIds.every(selection.selected.contains);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              // Le total, jamais la page : « Résultat · 21 élèves » sur une
              // page qui en montre dix reste vrai, l'inverse ne l'est pas.
              count: state.totalElements,
              subtitle: FeeControlQueryPhrase.subtitle(state, l10n),
              allSelected: allSelected,
              onTogglePage: pageIds.isEmpty
                  ? null
                  : () => context.read<FeeControlSelectionCubit>().togglePage(
                      pageIds,
                    ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            FeeControlDataTable(
              rows: state.rows,
              totalCount: state.totalElements,
              // Le MÊME cours que celui qui a ordonné la liste : relire le
              // cubit ici ferait afficher un taux qui ne correspond plus à
              // l'ordre des lignes.
              rate: state.lastQuery?.rate,
              selected: selection.selected,
              marked: selection.marked,
              isLoading: state.status == EnrollmentLoadStatus.loading,
              isError: state.status == EnrollmentLoadStatus.failure,
              loadingLabel: l10n.loadingStudents,
              errorLabel: state.errorMessage,
              emptyLabel: emptyLabel,
              currentPage: state.page + 1,
              totalPages: state.totalPages,
              pageSize: state.size,
              onPreviousPage: () => context.read<FeeControlBloc>().add(
                FeeControlPageRequested(state.page - 1),
              ),
              onNextPage: () => context.read<FeeControlBloc>().add(
                FeeControlPageRequested(state.page + 1),
              ),
              pageLabelBuilder: (current, total) =>
                  l10n.paginationPageIndicator(current, total),
              onViewRequested: onViewRequested,
              onRowTapped: onRowTapped,
              onSelectionToggled: (row) => context
                  .read<FeeControlSelectionCubit>()
                  .toggle(row.studentId),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final String subtitle;
  final bool allSelected;

  /// `null` sur une page vide : cocher zéro ligne n'est pas un geste.
  final VoidCallback? onTogglePage;

  const _Header({
    required this.count,
    required this.subtitle,
    required this.allSelected,
    required this.onTogglePage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: AppDimensions.spacingXS),
          child: Icon(
            Icons.fact_check_outlined,
            size: 18,
            color: AppColors.terreCuite,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Le nombre est annoncé : c'est la première chose qu'on veut
              // savoir, et un lecteur d'écran ne voit pas le tableau grandir.
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.feeControlResultTitle(count),
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (onTogglePage != null) ...[
          const SizedBox(width: AppDimensions.spacingS),
          EteeloButton.ghost(
            label: allSelected
                ? l10n.feeControlDeselectPage
                : l10n.feeControlSelectPage,
            icon: allSelected
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank,
            onPressed: onTogglePage,
            fullWidth: false,
            size: EteeloButtonSize.compact,
          ),
        ],
      ],
    );
  }
}
