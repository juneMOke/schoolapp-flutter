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
    return Container(
      color: EteeloDataTableTheme.footerBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: EteeloDataTableTheme.footerHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EteeloDataTableTheme.footerHorizontalPadding,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
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
                  ),
                ],
              ),
            ),
          ),
          if (config.pagination != null)
            DataTablePaginationBar(
              currentPage: config.pagination!.currentPage,
              totalPages: config.pagination!.totalPages,
              onPrevious: config.pagination!.onPrevious,
              onNext: config.pagination!.onNext,
              isLoading: config.pagination!.isLoading,
              pageLabel: config.pagination!.pageLabel,
            ),
        ],
      ),
    );
  }
}
