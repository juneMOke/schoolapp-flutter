import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau global de dégradation de session offline (ADR-010 D-08).
///
/// Monté au-dessus des routes (builder `MaterialApp.router`). Affiche :
/// - **WARNING** (J7–J21) : bandeau ambre permanent ;
/// - **READ_ONLY** (J21+ / triche horloge) : bandeau rouge « lecture seule » ;
/// - session **offline** en NORMAL : rappel discret.
/// Absent quand la session est en ligne et NORMAL (aucun décalage de layout).
class SessionDegradationBanner extends StatelessWidget {
  const SessionDegradationBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.sessionMode != current.sessionMode ||
          previous.isOffline != current.isOffline,
      builder: (context, state) {
        return Column(
          children: [
            ?_barFor(context, state),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget? _barFor(BuildContext context, AuthState state) {
    if (state.status != AuthStatus.authenticated) return null;
    final l10n = AppLocalizations.of(context)!;

    switch (state.sessionMode) {
      case SessionMode.readOnly:
        return _Bar(
          color: AppColors.error,
          icon: Icons.lock_outline_rounded,
          message: l10n.sessionReadOnlyBanner,
        );
      case SessionMode.warning:
        return _Bar(
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
          message: l10n.sessionWarningBanner,
        );
      case SessionMode.normal:
        if (state.isOffline) {
          return _Bar(
            color: AppColors.warning,
            icon: Icons.wifi_off_rounded,
            message: l10n.sessionOfflineBanner,
          );
        }
        return null;
    }
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.icon, required this.message});

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.blancCasse),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.blancCasse,
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
