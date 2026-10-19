import 'package:flutter/material.dart';

/// Un tableau ne s'écrase pas : sous [minWidth], il garde cette largeur et
/// défile horizontalement, sous un ascenseur toujours visible. Au-delà, il
/// prend toute la largeur reçue.
///
/// L'ascenseur est là pour la tablette : au doigt, rien ne disait qu'une vue
/// liste de 900 dp défilait de côté sur un écran de 800.
///
/// Le [child] doit tenir dans une largeur bornée — ses `Expanded` se
/// partagent alors [minWidth] au lieu de colonnes de quelques dp.
class EteeloMinWidthScroll extends StatefulWidget {
  final double minWidth;
  final Widget child;

  /// Le défilement horizontal, pour qui doit en suivre la position (colonne
  /// figée d'`EteeloColumnTable`). `null` : le sien.
  final ScrollController? controller;

  const EteeloMinWidthScroll({
    super.key,
    required this.minWidth,
    required this.child,
    this.controller,
  });

  @override
  State<EteeloMinWidthScroll> createState() => _EteeloMinWidthScrollState();
}

class _EteeloMinWidthScrollState extends State<EteeloMinWidthScroll> {
  ScrollController? _own;

  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= widget.minWidth) return widget.child;
      final sized = SizedBox(width: widget.minWidth, child: widget.child);
      // Déjà dans un défilement horizontal : la largeur suffit.
      if (!constraints.hasBoundedWidth) return sized;
      // L'ascenseur explicite remplace celui que le comportement de
      // défilement pose au bureau : deux pouces sur un même contrôleur, deux
      // cibles de glisser.
      return Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: sized,
          ),
        ),
      );
    },
  );
}
