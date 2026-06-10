import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login/login_banner_data.dart';

/// Bandeau d'erreur « en place » au-dessus du bouton de connexion (spec §08).
///
/// Une anatomie unique (icône + message [+ action] [+ code] [+ rebours]),
/// une tonalité par type. Annoncé comme `role=alert` (liveRegion) aux lecteurs
/// d'écran. La saisie de l'utilisateur n'est jamais perdue : ce n'est qu'une
/// surcouche d'information.
class LoginErrorBanner extends StatefulWidget {
  final LoginBannerData data;

  /// Appelé quand le compte à rebours (429) atteint zéro — point de branchement
  /// pour réactiver le bouton. Dormant tant que le 429 n'est pas émis.
  final VoidCallback? onCountdownEnd;

  const LoginErrorBanner({super.key, required this.data, this.onCountdownEnd});

  @override
  State<LoginErrorBanner> createState() => _LoginErrorBannerState();
}

class _LoginErrorBannerState extends State<LoginErrorBanner> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _startCountdownIfNeeded();
  }

  @override
  void didUpdateWidget(LoginErrorBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.countdownSeconds != oldWidget.data.countdownSeconds) {
      _timer?.cancel();
      _startCountdownIfNeeded();
    }
  }

  void _startCountdownIfNeeded() {
    final seconds = widget.data.countdownSeconds;
    if (seconds == null) return;
    _remaining = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
        widget.onCountdownEnd?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ({Color surface, Color border, Color text}) get _palette {
    switch (widget.data.tone) {
      case LoginBannerTone.error:
        return (
          surface: AppColors.loginBannerErrorSurface,
          border: AppColors.loginBannerErrorBorder,
          text: AppColors.loginBannerErrorText,
        );
      case LoginBannerTone.network:
        return (
          surface: AppColors.loginBannerNetworkSurface,
          border: AppColors.loginBannerNetworkBorder,
          text: AppColors.loginBannerNetworkText,
        );
      case LoginBannerTone.warning:
        return (
          surface: AppColors.loginBannerWarningSurface,
          border: AppColors.loginBannerWarningBorder,
          text: AppColors.loginBannerWarningText,
        );
    }
  }

  String get _message {
    final builder = widget.data.countdownMessage;
    if (widget.data.countdownSeconds != null && builder != null) {
      return builder(_remaining < 0 ? 0 : _remaining);
    }
    return widget.data.message;
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    final action = widget.data.action;
    final incidentCode = widget.data.incidentCode;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: p.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(widget.data.icon, size: 15, color: p.text),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: _message),
                        if (incidentCode != null)
                          TextSpan(
                            text: '  $incidentCode',
                            style: const TextStyle(
                              fontFamily: 'Roboto Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: p.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 6),
                    _BannerActionButton(action: action, color: p.text),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerActionButton extends StatelessWidget {
  final LoginBannerAction action;
  final Color color;

  const _BannerActionButton({required this.action, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: AppRadius.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
