import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/grid/staff_agent_card.dart';

/// Les agents en grille de cartes, autant de colonnes que la largeur en
/// permet.
class StaffAgentGrid extends StatelessWidget {
  final List<StaffFileRow> rows;
  final ValueChanged<StaffFileRow>? onOpen;

  const StaffAgentGrid({super.key, required this.rows, this.onOpen});

  @override
  Widget build(BuildContext context) => EteeloGridView(
    padding: EdgeInsets.zero,
    minItemWidth: AppDimensions.staffCardMinWidth,
    itemCount: rows.length,
    itemBuilder: (context, index) {
      final row = rows[index];
      return StaffAgentCard(
        row: row,
        onOpen: onOpen == null ? null : () => onOpen!(row),
      );
    },
  );
}
