import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_empty_state.dart';
import 'package:school_app_flutter/core/components/tables/data_table_error_state.dart';
import 'package:school_app_flutter/core/components/tables/data_table_footer_bar.dart';
import 'package:school_app_flutter/core/components/tables/data_table_header.dart';
import 'package:school_app_flutter/core/components/tables/data_table_loading_state.dart';
import 'package:school_app_flutter/core/components/tables/data_table_row_item.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Composant générique pour afficher une table de données - UTILISE TOKENS DESIGN SYSTEM
class DataTableView extends StatelessWidget {
  final List<DataTableRowSpec> rows;
  final DataTableViewConfig config;
  final Map<DataTableTrailingType, DataTableTrailingBuilder> trailingBuilders;
  final bool showRowDividers;

  const DataTableView({
    super.key,
    required this.rows,
    required this.config,
    this.trailingBuilders = const {},
    this.showRowDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showLeadingSlot = rows.any((row) => row.leading != null);
    final showTrailingSlot = rows.any(
      (row) => row.trailing.type != DataTableTrailingType.none,
    );

    final content = _buildStateContent(
      context,
      l10n,
      showLeadingSlot,
      showTrailingSlot,
    );

    return Semantics(
      container: true,
      liveRegion: config.isLoading || config.isError,
      label: config.semanticsLabel,
      child: ColoredBox(
        color: EteeloDataTableTheme.tableBackground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DataTableHeader(
              columns: config.columns,
              activeSortColumn: config.sortColumnIndex,
              sortAscending: config.sortAscending,
              onSortChanged: config.onSortChanged,
              showLeadingSlot: showLeadingSlot,
              showTrailingSlot: showTrailingSlot,
              density: config.density,
            ),
            const Divider(
              height: EteeloDataTableTheme.separatorThickness,
              thickness: EteeloDataTableTheme.separatorThickness,
              color: EteeloDataTableTheme.separatorColor,
            ),
            AnimatedSwitcher(
              duration: AppMotion.standard,
              switchInCurve: AppMotion.outCurve,
              switchOutCurve: AppMotion.inCurve,
              child: content,
            ),
            if (config.footer != null)
              const Divider(
                height: EteeloDataTableTheme.separatorThickness,
                thickness: EteeloDataTableTheme.separatorThickness,
                color: EteeloDataTableTheme.separatorColor,
              ),
            if (config.footer != null)
              DataTableFooterBar(config: config.footer!),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent(
    BuildContext context,
    AppLocalizations l10n,
    bool showLeadingSlot,
    bool showTrailingSlot,
  ) {
    if (config.isLoading) {
      return DataTableLoadingState(
        key: const ValueKey('data-table-loading'),
        label: config.loadingLabel,
      );
    }

    if (config.isError) {
      return DataTableErrorState(
        key: const ValueKey('data-table-error'),
        label: config.errorLabel ?? l10n.noResultsFound,
      );
    }

    if (rows.isEmpty) {
      return DataTableEmptyState(
        key: const ValueKey('data-table-empty'),
        label: config.emptyLabel ?? l10n.noResultsFound,
      );
    }

    return ListView.separated(
      key: const ValueKey('data-table-rows'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) => showRowDividers
          ? const Divider(
              height: EteeloDataTableTheme.separatorThickness,
              thickness: EteeloDataTableTheme.separatorThickness,
              color: EteeloDataTableTheme.separatorColor,
            )
          : const SizedBox.shrink(),
      itemBuilder: (context, index) => DataTableRowItem(
        key: ValueKey(rows[index].id),
        row: rows[index],
        columns: config.columns,
        isEven: index.isEven,
        trailingBuilders: trailingBuilders,
        density: config.density,
      ),
    );
  }
}
