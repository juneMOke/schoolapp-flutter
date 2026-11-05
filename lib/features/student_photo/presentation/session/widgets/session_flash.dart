import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le flash après une prise : voile blanc, la photo cerclée d'or, et l'élève
/// suivant au bout de 1,5 s — sauf « Reprendre ».
class SessionFlashOverlay extends StatefulWidget {
  final SessionFlash flash;
  final bool queued;
  final VoidCallback onAdvance;
  final VoidCallback onRetake;

  const SessionFlashOverlay({
    super.key,
    required this.flash,
    required this.queued,
    required this.onAdvance,
    required this.onRetake,
  });

  /// Le temps de voir la photo avant l'élève suivant.
  static const Duration advanceAfter = AppMotion.photoSessionAdvance;

  @override
  State<SessionFlashOverlay> createState() => _SessionFlashOverlayState();
}

class _SessionFlashOverlayState extends State<SessionFlashOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SessionFlashOverlay.advanceAfter, widget.onAdvance);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Le texte s'arrête à ces lignes, moins si la hauteur manque.
  static const int _maxTextLines = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = widget.queued
        ? l10n.photoSessionFlashQueued
        : l10n.photoSessionFlash;
    final style = AppTypography.titleSmall.copyWith(
      color: AppColors.textPrimary,
    );
    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: AppColors.photoFlash,
        child: LayoutBuilder(
          builder: (context, box) {
            final fit = _fit(context, box, message, style);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _photo(fit.side),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.queued) ...[
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: AppDimensions.photoIconSm,
                          color: AppColors.photoWaitInk,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          maxLines: fit.lines,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  EteeloButton.secondary(
                    label: l10n.photoRetake,
                    icon: Icons.replay_rounded,
                    fullWidth: false,
                    onPressed: () {
                      _timer?.cancel();
                      widget.onRetake();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// La photo d'abord : jusqu'à 160 dp, et jamais sous
  /// [AppDimensions.photoSessionFlashPreviewMin] tant que le texte peut
  /// céder — on lui retire des lignes (tronquées) avant de rogner la photo,
  /// puisque c'est sur elle qu'on décide « Reprendre ». Un viseur trop bas
  /// même pour une ligne donne à la photo ce qui reste.
  ({double side, int lines}) _fit(
    BuildContext context,
    BoxConstraints box,
    String message,
    TextStyle style,
  ) {
    final iconWidth = widget.queued
        ? AppDimensions.photoIconSm + AppSpacing.xs
        : 0.0;
    final textWidth = math.max(0.0, box.maxWidth - iconWidth);
    // Deux écarts et « Reprendre » (48 dp de cible).
    const fixed = 2 * AppSpacing.md + AppDimensions.minTouchTarget;
    double left(int lines) {
      final painter = TextPainter(
        // Le style tel que `Text` le rendra : hérité du thème, puis le nôtre.
        text: TextSpan(
          text: message,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
        maxLines: lines,
        ellipsis: '…',
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: textWidth);
      final height = painter.height;
      painter.dispose();
      return box.maxHeight - fixed - height;
    }

    const preview = AppDimensions.photoSessionFlashPreview;
    // Le plancher vaut pour la photo visible, dans son anneau.
    const floor =
        AppDimensions.photoSessionFlashPreviewMin +
        2 * AppDimensions.photoFlashRing;
    for (var lines = _maxTextLines; lines > 1; lines--) {
      final side = left(lines);
      if (side >= floor) {
        return (side: math.min(side, preview), lines: lines);
      }
    }
    return (side: math.max(0.0, math.min(left(1), preview)), lines: 1);
  }

  Widget _photo(double side) => Container(
    width: side,
    height: side,
    // La bordure repousse la photo : l'anneau reste entier.
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.orDoux,
        width: AppDimensions.photoFlashRing,
      ),
    ),
    child: ClipOval(
      child: Image.memory(
        widget.flash.photo,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    ),
  );
}
