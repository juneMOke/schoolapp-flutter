import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';

/// Densité visuelle supportée par les tableaux.
enum DataTableDensity { comfortable, compact }

extension DataTableDensityX on DataTableDensity {
  double get rowHeight => switch (this) {
    DataTableDensity.compact => EteeloDataTableTheme.rowHeightCompact,
    DataTableDensity.comfortable => EteeloDataTableTheme.rowHeightComfortable,
  };

  double get headerVerticalPadding => switch (this) {
    DataTableDensity.compact =>
      EteeloDataTableTheme.headerVerticalPaddingCompact,
    DataTableDensity.comfortable =>
      EteeloDataTableTheme.headerVerticalPaddingComfortable,
  };
}
