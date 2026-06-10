import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tonalité d'un bandeau d'erreur de connexion (spec §08).
enum LoginBannerTone { error, network, warning }

/// Action secondaire optionnelle d'un bandeau (Réessayer, Contacter l'admin…).
class LoginBannerAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const LoginBannerAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Données d'affichage d'un bandeau d'erreur « en place » au-dessus du bouton
/// de connexion (spec §08). Le widget [LoginErrorBanner] ne fait que rendre
/// cette description : tonalité, icône, message, action, code incident (500),
/// ou compte à rebours (429).
class LoginBannerData {
  final LoginBannerTone tone;
  final IconData icon;
  final String message;
  final LoginBannerAction? action;

  /// Code d'incident affiché en monospace pour une erreur serveur (500).
  final String? incidentCode;

  /// Durée initiale du compte à rebours (429). Quand non nul, le bandeau égrène
  /// les secondes via [countdownMessage].
  final int? countdownSeconds;

  /// Construit le message à chaque tick du rebours (429), avec les secondes
  /// restantes. Localisé par l'appelant.
  final String Function(int secondsLeft)? countdownMessage;

  const LoginBannerData({
    required this.tone,
    required this.icon,
    required this.message,
    this.action,
    this.incidentCode,
    this.countdownSeconds,
    this.countdownMessage,
  });

  /// Traduit une [AuthErrorKind] en bandeau prêt à afficher.
  ///
  /// 401 (identifiants) et réseau sont les seuls réellement émis aujourd'hui ;
  /// [AuthErrorKind.accountDisabled] et [AuthErrorKind.rateLimited] sont gérés
  /// mais dormants tant que le backend n'expose pas leurs signaux (spec §08).
  factory LoginBannerData.fromErrorKind(
    AuthErrorKind kind, {
    required AppLocalizations l10n,
    required VoidCallback onRetry,
    VoidCallback? onContactAdmin,
    int rateLimitSeconds = 30,
    String? incidentCode,
  }) {
    switch (kind) {
      case AuthErrorKind.invalidCredentials:
        return LoginBannerData(
          tone: LoginBannerTone.error,
          icon: Icons.error_outline_rounded,
          message: l10n.loginErrorInvalidCredentials,
        );
      case AuthErrorKind.network:
        return LoginBannerData(
          tone: LoginBannerTone.network,
          icon: Icons.wifi_off_rounded,
          message: l10n.loginErrorNetwork,
          action: LoginBannerAction(
            label: l10n.splashErrorRetry,
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        );
      case AuthErrorKind.accountDisabled:
        return LoginBannerData(
          tone: LoginBannerTone.warning,
          icon: Icons.shield_outlined,
          message: l10n.loginErrorAccountDisabled,
          action: onContactAdmin == null
              ? null
              : LoginBannerAction(
                  label: l10n.loginContactAdmin,
                  icon: Icons.mail_outline_rounded,
                  onTap: onContactAdmin,
                ),
        );
      case AuthErrorKind.rateLimited:
        return LoginBannerData(
          tone: LoginBannerTone.warning,
          icon: Icons.timer_outlined,
          message: l10n.loginErrorRateLimited(rateLimitSeconds),
          countdownSeconds: rateLimitSeconds,
          countdownMessage: (s) => l10n.loginErrorRateLimited(s),
        );
      case AuthErrorKind.server:
      case AuthErrorKind.generic:
        return LoginBannerData(
          tone: LoginBannerTone.error,
          icon: Icons.warning_amber_rounded,
          message: l10n.loginErrorServer,
          incidentCode: incidentCode,
          action: LoginBannerAction(
            label: l10n.splashErrorRetry,
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        );
    }
  }
}
