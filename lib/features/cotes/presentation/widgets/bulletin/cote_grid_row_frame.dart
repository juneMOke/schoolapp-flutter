import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_context.dart';

/// L'entrée d'une ligne : celles qu'un dépliage révèle se posent au lieu
/// d'apparaître. La clé suit le contenu : replier une branche ne remonte pas
/// les lignes voisines, ni la cellule qui a le focus.
Widget coteRowReveal(CoteGridRow row, Widget child) => EteeloEntrance(
  key: ValueKey(row.id),
  index: 0,
  offsetY: AppDimensions.coteRowRevealOffset,
  duration: AppMotion.standard,
  child: child,
);

/// Le fond d'un cours dans une zone. Le survol vaut pour la ligne entière, à
/// travers les trois zones : [child] ne se reconstruit pas pour autant.
class CoteCourseRowFrame extends StatelessWidget {
  final CoteCourseRow row;
  final CoteGridContext grid;
  final EdgeInsets? padding;
  final Alignment? alignment;
  final Widget child;

  const CoteCourseRowFrame({
    super.key,
    required this.row,
    required this.grid,
    required this.child,
    this.padding,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final id = row.cours.coursId;
    return MouseRegion(
      onEnter: (_) => grid.hoveredCours.value = id,
      onExit: (_) {
        if (grid.hoveredCours.value == id) grid.hoveredCours.value = null;
      },
      child: ValueListenableBuilder<String?>(
        valueListenable: grid.hoveredCours,
        child: child,
        builder: (context, hovered, child) => AnimatedContainer(
          duration: AppMotion.micro,
          height: grid.heights.course,
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            color: hovered == id
                ? row.tone.soft
                : row.shaded
                ? row.tone.wash
                : AppColors.surfaceRaised,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: child,
        ),
      ),
    );
  }
}
