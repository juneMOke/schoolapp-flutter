import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_results_frame.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';

/// Un registre en cartes, pour un agent comme pour un élève : la grille dans
/// le cadre de résultats des tables, à la largeur de carte du registre.
class PresenceCardGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const PresenceCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) => EteeloResultsFrame(
    tone: ListingTones.table,
    child: EteeloGridView(
      padding: EdgeInsets.zero,
      minItemWidth: AppDimensions.presenceMarkCardMinWidth,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    ),
  );
}
