import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Les indicateurs d'une fiche mensuelle : quatre de front sur une tablette
/// en paysage, deux par ligne au-dessous.
class PresenceKpiGrid extends StatelessWidget {
  final List<Widget> tiles;

  const PresenceKpiGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth > AppDimensions.presenceMarkKpiWideBreakpoint
          ? 4
          : 2;
      final width =
          (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final tile in tiles) SizedBox(width: width, child: tile),
        ],
      );
    },
  );
}
