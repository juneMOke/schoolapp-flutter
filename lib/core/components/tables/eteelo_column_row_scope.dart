import 'package:flutter/widgets.dart';

/// Ce qu'un [EteeloColumnTable] teinté dit à chacune de ses lignes : le fond
/// de zébrure d'une ligne paire. Une ligne qui porte son propre fond (total,
/// mois en cours) le garde.
class EteeloColumnRowScope extends InheritedWidget {
  /// `null` : ligne impaire, ou table sans teinte.
  final Color? zebra;

  const EteeloColumnRowScope({
    super.key,
    required this.zebra,
    required super.child,
  });

  static Color? zebraOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EteeloColumnRowScope>()?.zebra;

  @override
  bool updateShouldNotify(EteeloColumnRowScope oldWidget) =>
      zebra != oldWidget.zebra;
}
