import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_pagination_bar.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Footer uniforme de table avec pagination integree.
class DataTableFooterBar extends StatelessWidget {
  final DataTableFooterConfig config;

  const DataTableFooterBar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summaryWidget = _buildSummaryWidget(l10n);

    final pagination = config.pagination == null
        ? null
        : DataTablePaginationBar(
            currentPage: config.pagination!.currentPage,
            totalPages: config.pagination!.totalPages,
            onPrevious: config.pagination!.onPrevious,
            onNext: config.pagination!.onNext,
            isLoading: config.pagination!.isLoading,
            pageLabel: config.pagination!.pageLabel,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            constraints.maxWidth < AppBreakpoints.tableFooterStackMax;

        return Container(
          color: EteeloDataTableTheme.footerBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: EteeloDataTableTheme.footerHorizontalPadding,
            vertical: AppDimensions.spacingS,
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    summaryWidget,
                    if (pagination != null) ...[
                      const SizedBox(height: AppDimensions.spacingXS),
                      pagination,
                    ],
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    summaryWidget,
                    if (pagination != null) ...[
                      const Spacer(),
                      Flexible(child: pagination),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSummaryWidget(AppLocalizations l10n) {
    final total = config.total;
    final unit = config.unit;
    if (total != null && unit != null) {
      final range = _buildRange(total);
      return Text(
        l10n.paginationRange(range.$1, range.$2, total, unit),
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: const BoxDecoration(
        color: EteeloDataTableTheme.footerChipBackground,
        borderRadius: AppRadius.brLg,
      ),
      child: Text(
        config.label,
        style: EteeloDataTableTheme.cellStrongStyle.copyWith(
          color: EteeloDataTableTheme.footerChipTextColor,
        ),
      ),
    );
  }

  (int, int) _buildRange(int total) {
    if (total <= 0) {
      return (0, 0);
    }

    final pagination = config.pagination;
    if (pagination == null) {
      return (1, total);
    }

    final start = ((pagination.currentPage - 1) * pagination.pageSize) + 1;
    final end = (pagination.currentPage * pagination.pageSize).clamp(0, total);
    final boundedStart = start.clamp(1, total);
    return (boundedStart, end);
  }
}
