import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_statut_visual.dart';

/// Le numéro d'un chapitre (`01`, `02`…) aux couleurs de son statut : la
/// position dans le programme, recalculée quand on réordonne.
class ChapitreNumeroTile extends StatelessWidget {
  final int numero;
  final ChapitreStatut statut;
  final double size;
  final TextStyle textStyle;

  const ChapitreNumeroTile({
    super.key,
    required this.numero,
    required this.statut,
    required this.size,
    this.textStyle = AppTypography.labelLarge,
  });

  @override
  Widget build(BuildContext context) {
    final visual = ChapitreStatutVisual.of(statut);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: visual.soft,
          borderRadius: size > 40 ? AppRadius.brLg : AppRadius.brSm,
        ),
        child: Text(
          numero.toString().padLeft(2, '0'),
          style: textStyle.copyWith(
            color: visual.accent,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
