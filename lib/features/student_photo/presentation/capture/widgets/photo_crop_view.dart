import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';

/// La zone de recadrage : un carré où l'image glisse et se zoome sous un
/// cercle, et le curseur de zoom.
///
/// Glisser déplace ; pincer, la molette ou le curseur zooment de 1× à 3× ;
/// les flèches déplacent de 8 dp. L'image couvre toujours le carré
/// ([CropWindow] borne le déplacement).
class PhotoCropView extends StatelessWidget {
  final Uint8List source;
  final CropWindow window;
  final bool mirror;
  final ValueChanged<CropWindow> onChanged;
  final String zoomLabel;

  const PhotoCropView({
    super.key,
    required this.source,
    required this.window,
    required this.onChanged,
    required this.zoomLabel,
    this.mirror = false,
  });

  /// Pas d'un appui sur une flèche, en dp.
  static const double arrowStep = 8;

  /// Pas d'un cran de molette sur le zoom.
  static const double wheelStep = 0.1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          AppDimensions.photoCropSide,
          constraints.maxWidth,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _square(side),
            const SizedBox(height: AppSpacing.md),
            SizedBox(width: side, child: _zoomSlider()),
          ],
        );
      },
    );
  }

  Widget _square(double side) {
    final scale = side / window.side;
    final image = Image.memory(
      source,
      width: window.imageWidth * scale,
      height: window.imageHeight * scale,
      fit: BoxFit.fill,
      gaplessPlayback: true,
    );
    late double startZoom;
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _onKey(event, side),
      child: Listener(
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent) {
            final direction = signal.scrollDelta.dy > 0 ? -1 : 1;
            onChanged(window.zoomTo(window.zoom + direction * wheelStep));
          }
        },
        child: GestureDetector(
          onScaleStart: (_) => startZoom = window.zoom,
          onScaleUpdate: (details) {
            var next = window.panBy(
              details.focalPointDelta.dx,
              details.focalPointDelta.dy,
              side,
            );
            if (details.pointerCount > 1) {
              next = next.zoomTo(startZoom * details.scale);
            }
            onChanged(next);
          },
          child: SizedBox.square(
            dimension: side,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimensions.photoViewfinderRadius,
              ),
              child: ColoredBox(
                color: AppColors.photoViewfinder,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: -window.left * scale,
                      top: -window.top * scale,
                      child: mirror
                          ? Transform.flip(flipX: true, child: image)
                          : image,
                    ),
                    const Positioned.fill(
                      child: CustomPaint(painter: _CropCirclePainter()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKey(KeyEvent event, double side) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Flèche à droite : l'image glisse vers la droite.
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const Offset(-arrowStep, 0),
      LogicalKeyboardKey.arrowRight => const Offset(arrowStep, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, -arrowStep),
      LogicalKeyboardKey.arrowDown => const Offset(0, arrowStep),
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    onChanged(window.panBy(delta.dx, delta.dy, side));
    return KeyEventResult.handled;
  }

  Widget _zoomSlider() {
    return Row(
      children: [
        const Icon(
          Icons.zoom_in_rounded,
          size: AppDimensions.photoIconSm,
          color: AppColors.onPhotoCaptureMuted,
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: AppColors.onPhotoCapture,
              inactiveTrackColor: AppColors.onPhotoCaptureVeil,
              thumbColor: AppColors.orDoux,
              overlayColor: AppColors.onPhotoCaptureFaint,
            ),
            child: Slider(
              value: window.zoom,
              min: CropWindow.minZoom,
              max: CropWindow.maxZoom,
              label: zoomLabel,
              semanticFormatterCallback: (value) =>
                  '$zoomLabel ${value.toStringAsFixed(1)}×',
              onChanged: (value) => onChanged(window.zoomTo(value)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Le cercle retenu, retiré de 10 dp, bordé d'or doux ; l'extérieur est
/// assombri à 55 %.
class _CropCirclePainter extends CustomPainter {
  const _CropCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromLTWH(
      AppDimensions.photoCropInset,
      AppDimensions.photoCropInset,
      size.width - 2 * AppDimensions.photoCropInset,
      size.height - 2 * AppDimensions.photoCropInset,
    );
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(circle);
    canvas.drawPath(shade, Paint()..color = AppColors.photoCropShade);
    canvas.drawOval(
      circle,
      Paint()
        ..color = AppColors.orDoux
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppDimensions.photoGuideStroke,
    );
  }

  @override
  bool shouldRepaint(_CropCirclePainter oldDelegate) => false;
}
