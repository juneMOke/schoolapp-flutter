import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Ce qu'un [EteeloColumnTable] dit à son en-tête et à ses lignes de
/// l'alignement de ses colonnes : une colonne alignée à gauche qui suit un
/// montant aligné à droite s'en écarte. Sans cet écart, les deux se
/// touchaient — « MONTANTÉCHÉANCIER », « RESTESTATUT ».
class EteeloColumnGap extends InheritedWidget {
  /// Les colonnes alignées à droite (montants).
  final Set<int> endAligned;

  const EteeloColumnGap({
    super.key,
    required this.endAligned,
    required super.child,
  });

  /// L'écart entre un montant et la colonne alignée à gauche qui le suit.
  static const double gap = AppSpacing.md;

  static EteeloColumnGap? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EteeloColumnGap>();

  /// Le retrait de la cellule [index] : en tête d'une colonne alignée à
  /// gauche qui suit une colonne alignée à droite ; `null` ailleurs.
  EdgeInsetsDirectional? paddingOf(int index) =>
      index > 0 && endAligned.contains(index - 1) && !endAligned.contains(index)
      ? const EdgeInsetsDirectional.only(start: gap)
      : null;

  @override
  bool updateShouldNotify(EteeloColumnGap oldWidget) =>
      endAligned != oldWidget.endAligned;
}
