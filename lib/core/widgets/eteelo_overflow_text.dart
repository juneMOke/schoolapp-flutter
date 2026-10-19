import 'package:flutter/material.dart';

/// Un texte coupé par des points de suspension qui, coupé, se lit en entier
/// au survol (et à l'appui long) : un nom d'élève ou un libellé de frais
/// tronqué dans une colonne étroite ne se devine pas.
///
/// L'info-bulle n'est posée que si le texte déborde vraiment : un texte qui
/// tient ne la double pas.
class EteeloOverflowText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;

  const EteeloOverflowText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return label;
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: DefaultTextStyle.of(context).style.merge(style),
          ),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return overflows ? Tooltip(message: text, child: label) : label;
      },
    );
  }
}
