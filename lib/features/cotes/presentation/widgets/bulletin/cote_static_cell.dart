import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une cellule sans saisie : total de groupe, colonne clôturée, cours sans
/// examen. Non focusable.
class CoteStaticCell extends StatelessWidget {
  final String text;
  final double height;
  final Color background;
  final Color ink;
  final FontWeight weight;

  /// Souligné pour un score sous la moitié (cf. `coteScoreMark`).
  final TextDecoration decoration;
  final String? tooltip;
  final String? semanticLabel;

  const CoteStaticCell({
    super.key,
    required this.text,
    required this.height,
    this.background = AppColors.papier,
    this.ink = AppColors.textSecondary,
    this.weight = FontWeight.w500,
    this.decoration = TextDecoration.none,
    this.tooltip,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brSm,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: AppTypography.bodyMedium.copyWith(
            color: ink,
            fontWeight: weight,
            decoration: decoration,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
    final labelled = semanticLabel == null
        ? body
        : Semantics(
            readOnly: true,
            label: semanticLabel,
            value: text,
            child: ExcludeSemantics(child: body),
          );
    final message = tooltip;
    return message == null
        ? labelled
        : Tooltip(message: message, child: labelled);
  }
}
