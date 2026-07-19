import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';

/// Vue consommée par la présentation après un login (online ou offline) : la
/// session applicative + son mode de dégradation courant + l'origine (offline ?).
class AuthSessionSnapshot {
  final AuthSession session;
  final SessionMode mode;
  final bool isOffline;

  const AuthSessionSnapshot({
    required this.session,
    required this.mode,
    required this.isOffline,
  });
}
