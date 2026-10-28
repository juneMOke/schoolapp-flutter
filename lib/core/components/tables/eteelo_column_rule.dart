import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Ce qu'un [EteeloColumnTable] dit à son en-tête et à ses lignes quand un
/// filet vertical sépare deux groupes de colonnes (les montants, puis ce qui
/// les commente) : le filet suit la colonne [after], sur toute la hauteur de
/// chaque rangée, et les deux cellules qui le bordent s'en écartent.
class EteeloColumnRule extends InheritedWidget {
  /// L'index de la colonne que le filet suit.
  final int after;
  final List<double?> widths;
  final Color color;

  const EteeloColumnRule({
    super.key,
    required this.after,
    required this.widths,
    required this.color,
    required super.child,
  });

  static EteeloColumnRule? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EteeloColumnRule>();

  /// L'écart d'une cellule au filet : en fin de la colonne [after], en tête
  /// de la suivante ; `null` ailleurs.
  EdgeInsetsDirectional? paddingOf(int index) => index == after
      ? const EdgeInsetsDirectional.only(end: AppSpacing.sm)
      : index == after + 1
      ? const EdgeInsetsDirectional.only(start: AppSpacing.sm)
      : null;

  /// Peint le filet sous une rangée dont les cellules partent à [inset] de
  /// ses bords — sa marge. Dessous, et non dessus : une colonne figée qui
  /// passe sur lui le masque, et un en-tête plein le cache.
  static Widget under(
    BuildContext context, {
    required Widget child,
    double inset = AppSpacing.sm,
  }) {
    final rule = maybeOf(context);
    if (rule == null) return child;
    return CustomPaint(
      painter: _RulePainter(
        after: rule.after,
        widths: rule.widths,
        color: rule.color,
        inset: inset,
      ),
      child: child,
    );
  }

  @override
  bool updateShouldNotify(EteeloColumnRule oldWidget) =>
      after != oldWidget.after ||
      color != oldWidget.color ||
      widths != oldWidget.widths;
}

class _RulePainter extends CustomPainter {
  final int after;
  final List<double?> widths;
  final Color color;
  final double inset;

  const _RulePainter({
    required this.after,
    required this.widths,
    required this.color,
    required this.inset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // La colonne sans largeur prend ce que les autres laissent, comme dans
    // la rangée.
    final fixed = widths.fold<double>(0, (sum, width) => sum + (width ?? 0));
    final flexible = (size.width - 2 * inset - fixed).clamp(0.0, size.width);
    var x = inset;
    for (var i = 0; i <= after && i < widths.length; i++) {
      x += widths[i] ?? flexible;
    }
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RulePainter oldDelegate) =>
      after != oldDelegate.after ||
      color != oldDelegate.color ||
      inset != oldDelegate.inset ||
      widths != oldDelegate.widths;
}
