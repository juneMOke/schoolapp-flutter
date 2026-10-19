import 'package:flutter/widgets.dart';

/// La première colonne d'un `EteeloColumnTable` qui défile de côté : elle
/// reste à l'écran pendant que les montants passent dessous — sans elle, sur
/// une tablette en portrait, on lisait un net sans savoir de quel agent.
///
/// Les lignes sont construites par l'appelant, d'un seul tenant : on ne peut
/// pas les couper en deux tableaux. Chaque rangée (`EteeloColumns`) lit donc
/// ce relais et translate sa première cellule du décalage de défilement,
/// par-dessus les autres. Une seule ligne, un seul geste, une seule lecture.
class EteeloFrozenColumn extends InheritedWidget {
  /// Le défilement horizontal du tableau.
  final ScrollController controller;

  /// Largeur de la colonne figée, dans la largeur plancher du tableau.
  final double width;

  /// Le tableau défile de côté. Le relais reste posé quand il ne défile pas :
  /// l'arbre ne change pas de forme au passage du seuil, et le défilement
  /// n'est jamais recréé (deux défilements sur un même contrôleur).
  final bool active;

  const EteeloFrozenColumn({
    super.key,
    required this.controller,
    required this.width,
    required this.active,
    required super.child,
  });

  static EteeloFrozenColumn? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EteeloFrozenColumn>();

  /// Décalage courant : la colonne se pose à cette abscisse de sa rangée.
  double get offset => controller.positions.length == 1 ? controller.offset : 0;

  @override
  bool updateShouldNotify(EteeloFrozenColumn oldWidget) =>
      controller != oldWidget.controller ||
      width != oldWidget.width ||
      active != oldWidget.active;
}
