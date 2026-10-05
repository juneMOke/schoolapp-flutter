import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Le viseur 4:3 : le flux en direct, recouvert d'un guide ovale qui laisse
/// voir le visage et assombrit le reste. [overlay] remplace le flux (demande
/// d'accès, caméra absente).
class PhotoViewfinder extends StatelessWidget {
  final CameraSession? session;
  final String tip;
  final Widget? overlay;

  const PhotoViewfinder({
    super.key,
    required this.session,
    required this.tip,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    // Le capteur livre son rapport en paysage ; `CameraPreview` le retourne
    // de lui-même quand l'appareil est tenu en portrait.
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final ratio = session?.previewAspectRatio ?? 4 / 3;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimensions.photoViewfinderRadius,
        ),
        child: ColoredBox(
          color: AppColors.photoViewfinder,
          child:
              overlay ??
              Stack(
                fit: StackFit.expand,
                children: [
                  if (session != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      // Une taille de référence au rapport du flux : `FittedBox`
                      // la met à l'échelle du viseur sans la déformer.
                      child: SizedBox(
                        width: portrait ? 1 : ratio,
                        height: portrait ? ratio : 1,
                        child: session.buildPreview(),
                      ),
                    ),
                  const CustomPaint(painter: OvalGuidePainter()),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Text(
                      tip,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onPhotoCaptureMuted,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

/// Le guide ovale : 40 % de la largeur, au format 4:5, centré à 46 % de la
/// hauteur ; bordure or doux, extérieur assombri à 50 %. Le carré que la
/// séance retient automatiquement (`CropWindow.ovalGuide`) l'englobe.
class OvalGuidePainter extends CustomPainter {
  const OvalGuidePainter();

  static Rect ovalIn(Size size) {
    final width = size.width * 0.40;
    final height = width * 5 / 4;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: width,
      height: height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final oval = ovalIn(size);
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(shade, Paint()..color = AppColors.photoGuideShade);
    canvas.drawOval(
      oval,
      Paint()
        ..color = AppColors.orDoux
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppDimensions.photoGuideStroke,
    );
  }

  @override
  bool shouldRepaint(OvalGuidePainter oldDelegate) => false;
}
