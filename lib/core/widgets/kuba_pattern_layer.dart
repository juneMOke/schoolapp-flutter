import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Facteur de sur-échantillonnage : on rasterise la tuile à une résolution
/// supérieure pour garder le motif net sur les écrans HiDPI, puis le shader
/// la réduit à sa taille logique ([AppDimensions.kubaTileSize]).
const double _kubaRasterScale = 3.0;

/// Cache process-wide : le motif Kuba n'est rasterisé qu'une seule fois,
/// partagé par toutes les pages.
Future<ui.Image>? _kubaTileFuture;

Future<ui.Image> _loadKubaTile() {
  return _kubaTileFuture ??= _rasterizeKubaTile();
}

/// Charge `assets/patterns/kuba_tile.svg`, le rend en [ui.Picture] puis le
/// rasterise en [ui.Image] (sur-échantillonnée) réutilisable comme source de
/// shader répété.
///
/// L'opacité finale (7 %) est **cuite directement dans la tuile** via un
/// `saveLayer` ponctuel à la rasterisation : le painter n'a donc plus besoin
/// de `saveLayer` plein écran à chaque peinture.
Future<ui.Image> _rasterizeKubaTile() async {
  const loader = SvgAssetLoader('assets/patterns/kuba_tile.svg');
  final pictureInfo = await vg.loadPicture(loader, null);

  final dimension = AppDimensions.kubaTileSize * _kubaRasterScale;
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..saveLayer(
      Rect.fromLTWH(0, 0, dimension, dimension),
      Paint()
        ..color = Colors.white.withValues(alpha: AppDimensions.kubaOpacity),
    )
    ..scale(_kubaRasterScale)
    ..drawPicture(pictureInfo.picture)
    ..restore();
  final picture = recorder.endRecording();

  final image = await picture.toImage(dimension.round(), dimension.round());

  pictureInfo.picture.dispose();
  picture.dispose();
  return image;
}

/// Peint le filigrane Kuba en tuilant la [ui.Image] (déjà à 7 % d'opacité) via
/// un [ui.ImageShader] en `TileMode.repeated`. Aucun `saveLayer` ici :
/// l'opacité a été appliquée une fois pour toutes à la rasterisation.
class _KubaTilePainter extends CustomPainter {
  const _KubaTilePainter(this.tile);

  final ui.Image tile;

  @override
  void paint(Canvas canvas, Size size) {
    // Réduit la tuile sur-échantillonnée à sa taille logique : chaque pavé
    // occupe [AppDimensions.kubaTileSize] px logiques.
    final inverseScale = 1 / _kubaRasterScale;
    final matrix = Matrix4.identity()
      ..scaleByDouble(inverseScale, inverseScale, 1, 1);
    final shader = ui.ImageShader(
      tile,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      matrix.storage,
    );

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_KubaTilePainter oldDelegate) => oldDelegate.tile != tile;
}

/// Filigrane Kuba tuilé sur toute la surface, derrière le contenu.
///
/// Le SVG est rasterisé une seule fois (cache process-wide) ; le premier frame
/// reste transparent le temps du chargement asynchrone — acceptable pour un
/// motif à 7 % d'opacité. Isolé dans un [RepaintBoundary] pour ne jamais se
/// repeindre suite à un repaint d'un ancêtre.
class KubaPatternLayer extends StatelessWidget {
  const KubaPatternLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: FutureBuilder<ui.Image>(
            future: _loadKubaTile(),
            builder: (context, snapshot) {
              final tile = snapshot.data;
              if (tile == null) {
                return const SizedBox.expand();
              }
              return CustomPaint(
                painter: _KubaTilePainter(tile),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
}
