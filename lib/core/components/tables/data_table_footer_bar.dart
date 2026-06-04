import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_pagination_bar.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Footer uniforme de table avec pagination integree.
class DataTableFooterBar extends StatelessWidget {
  final DataTableFooterConfig config;

  const DataTableFooterBar({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final summaryChip = Container(
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
        final isNarrow = constraints.maxWidth < 560;

        return Container(
          color: EteeloDataTableTheme.footerBackground,
          padding: const EdgeInsets.symmetric(
            horizontal: EteeloDataTableTheme.footerHorizontalPadding,
            vertical: 8,
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    summaryChip,
                    if (pagination != null) ...[
                      const SizedBox(height: 4),
                      pagination,
                    ],
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    summaryChip,
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
}
