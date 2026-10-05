import 'dart:async';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: AppColors.photoFlash,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppDimensions.photoSessionFlashPreview,
                height: AppDimensions.photoSessionFlashPreview,
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
              ),
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
                      widget.queued
                          ? l10n.photoSessionFlashQueued
                          : l10n.photoSessionFlash,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
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
        ),
      ),
    );
  }
}
