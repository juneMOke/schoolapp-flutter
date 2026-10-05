import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le cercle vide de l'emplacement : un pointillé qui se lit « à remplir »,
/// et qui est lui-même le bouton caméra.
class PhotoSlotEmptyCircle extends StatefulWidget {
  final VoidCallback? onTap;
  final String semanticLabel;

  const PhotoSlotEmptyCircle({
    super.key,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  State<PhotoSlotEmptyCircle> createState() => _PhotoSlotEmptyCircleState();
}

class _PhotoSlotEmptyCircleState extends State<PhotoSlotEmptyCircle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? AppColors.bleuArdoise : AppColors.borderStrong;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: CustomPaint(
            painter: _DashedCirclePainter(
              color: color,
              fill: _hover ? AppColors.stateHover : AppColors.surfaceAlt,
            ),
            child: SizedBox.square(
              dimension: AppDimensions.photoSlotCircle,
              child: Icon(
                Icons.photo_camera_outlined,
                size: AppSpacing.xxl,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final Color fill;

  const _DashedCirclePainter({required this.color, required this.fill});

  static const double _dash = 6;
  static const double _gap = 5;
  static const double _stroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _stroke / 2;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (_dash + _gap)).floor();
    final sweep = _dash / radius;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * 2 * math.pi / count,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.fill != fill;
}

/// Un lien de 32 dp sous la photo (Reprendre · Recadrer · Retirer).
class PhotoSlotLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  const PhotoSlotLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.photoSlotLinkHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        foregroundColor: danger ? AppColors.error : AppColors.bleuArdoise,
        textStyle: AppTypography.labelMedium,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

/// La confirmation du retrait, en place : « Retirer la photo ? » Non / Retirer.
class PhotoSlotRemoveConfirm extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  const PhotoSlotRemoveConfirm({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.photoRemoveConfirm,
          textAlign: TextAlign.center,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhotoSlotLink(label: l10n.photoNo, onPressed: onCancel),
            PhotoSlotLink(
              label: l10n.photoRemove,
              onPressed: onConfirm,
              danger: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// La ligne d'état sous l'emplacement : facultatif, en attente d'envoi, ou
/// refusée par le serveur. Jamais en erreur pour une absence de photo.
class PhotoSlotCaption extends StatelessWidget {
  final String text;
  final bool alert;
  final IconData? icon;

  const PhotoSlotCaption({
    super.key,
    required this.text,
    this.alert = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert ? AppColors.error : AppColors.textMuted;
    final icon = this.icon;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppDimensions.photoIconXs, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
