import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';

/// Résultat de l'évaluation de fraîcheur d'une session offline (ADR-010 D-08).
class SessionEvaluation {
  /// Le refresh token est expiré (borne dure D-07) → reconnexion online exigée.
  final bool refreshExpired;

  /// Saut d'horloge arrière détecté (D-10) : le device prétend être **avant** le
  /// dernier contact serveur, ce qui est impossible légitimement.
  final bool clockTampered;

  /// Mode de dégradation courant (non significatif si [refreshExpired]).
  final SessionMode mode;

  const SessionEvaluation({
    required this.refreshExpired,
    required this.mode,
    this.clockTampered = false,
  });
}

/// Calcul **pur** de la dégradation graduée (ADR-010 D-07/D-08).
///
/// Ancrage de vérité : `now − lastServerSeenAt`, **jamais** `sessionStartedAt`.
/// Règle d'or : le temps qui passe ne peut que *dégrader* le mode ; seul un
/// contact serveur (qui avance `lastServerSeenAt`) peut l'améliorer.
class SessionFreshness {
  const SessionFreshness._();

  static SessionEvaluation evaluate({
    required int lastServerSeenAt,
    required int? refreshExpiresAt,
    required int nowMs,
    Duration warningThreshold = AppConstants.sessionWarningThreshold,
    Duration readOnlyThreshold = AppConstants.sessionReadOnlyThreshold,
  }) {
    if (refreshExpiresAt != null && nowMs >= refreshExpiresAt) {
      return const SessionEvaluation(
        refreshExpired: true,
        mode: SessionMode.readOnly,
      );
    }

    final elapsedMs = nowMs - lastServerSeenAt;

    // Anti-triche horloge (D-10) : un `elapsed` négatif = le device se prétend
    // AVANT le dernier contact serveur → saut arrière → READ_ONLY. Tolérance de
    // quelques minutes pour absorber une dérive d'horloge bénigne / la latence
    // réseau du header Date. Robuste au redémarrage (pas de monotone requis).
    const clockSkewToleranceMs = 5 * 60 * 1000;
    if (elapsedMs < -clockSkewToleranceMs) {
      return const SessionEvaluation(
        refreshExpired: false,
        clockTampered: true,
        mode: SessionMode.readOnly,
      );
    }

    final SessionMode mode;
    if (elapsedMs < warningThreshold.inMilliseconds) {
      mode = SessionMode.normal;
    } else if (elapsedMs < readOnlyThreshold.inMilliseconds) {
      mode = SessionMode.warning;
    } else {
      mode = SessionMode.readOnly;
    }
    return SessionEvaluation(refreshExpired: false, mode: mode);
  }
}
