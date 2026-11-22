import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Les tuiles du bandeau en rangées souples (maquette : `flex: 1 1 150px`,
/// `flex-wrap`) : autant de tuiles par rangée que la largeur en tient, et la
/// dernière rangée s'étire. Les tuiles d'une rangée ont la même hauteur.
class HeroTilesWrap extends StatelessWidget {
  final List<Widget> children;

  const HeroTilesWrap({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = AppSpacing.md - AppSpacing.xs / 2;
      final fit =
          ((constraints.maxWidth + gap) /
                  (AppDimensions.calendarHeroTileMinWidth + gap))
              .floor();
      final perRow = fit.clamp(1, children.length);
      final rows = <List<Widget>>[
        for (var i = 0; i < children.length; i += perRow)
          children.sublist(i, (i + perRow).clamp(0, children.length)),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) const SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, tile) in row.indexed) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(child: tile),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
