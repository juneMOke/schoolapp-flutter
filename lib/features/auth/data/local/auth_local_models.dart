/// Modèles de lignes des tables `auth_local` (ADR-010 §5). Purement data —
/// mapping SQLite ↔ Dart, sans logique métier.
library;

import 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart';

export 'package:school_app_flutter/features/auth/domain/entities/session_mode.dart'
    show SessionMode;

/// Ligne de `auth_local_user` — un utilisateur vu online au moins une fois sur
/// ce device. `userId` = claim `uid` du JWT (UUID serveur).
class AuthLocalUserRecord {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String schoolId;
  final String passwordVerifier;
  final String verifierSalt;
  final int userVersion;
  final int firstOnlineLoginAt;
  final int lastServerSeenAt;
  final int? sessionStartedAt;

  /// Borne offline par utilisateur (amendement m4) : borne refresh du dernier
  /// contact online de CE compte. Survit au logout, brûlée sur révocation
  /// (D-09). `null` = pas de fenêtre → reconnexion online exigée.
  final int? refreshExpiresAt;

  const AuthLocalUserRecord({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.schoolId,
    required this.passwordVerifier,
    required this.verifierSalt,
    required this.userVersion,
    required this.firstOnlineLoginAt,
    required this.lastServerSeenAt,
    this.sessionStartedAt,
    this.refreshExpiresAt,
  });

  factory AuthLocalUserRecord.fromMap(Map<String, Object?> map) {
    return AuthLocalUserRecord(
      userId: map['user_id'] as String,
      email: map['email'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      role: map['role'] as String,
      schoolId: map['school_id'] as String,
      passwordVerifier: map['password_verifier'] as String,
      verifierSalt: map['verifier_salt'] as String,
      userVersion: map['user_version'] as int,
      firstOnlineLoginAt: map['first_online_login_at'] as int,
      lastServerSeenAt: map['last_server_seen_at'] as int,
      sessionStartedAt: map['session_started_at'] as int?,
      refreshExpiresAt: map['refresh_expires_at'] as int?,
    );
  }

  Map<String, Object?> toMap() => {
    'user_id': userId,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'role': role,
    'school_id': schoolId,
    'password_verifier': passwordVerifier,
    'verifier_salt': verifierSalt,
    'user_version': userVersion,
    'first_online_login_at': firstOnlineLoginAt,
    'last_server_seen_at': lastServerSeenAt,
    'session_started_at': sessionStartedAt,
    'refresh_expires_at': refreshExpiresAt,
  };
}

/// Ligne de `auth_local_session` — singleton (`id = 1`).
class AuthLocalSessionRecord {
  final String userId;
  final SessionMode degradedMode;
  final int refreshExpiresAt;
  final int lastEvaluatedAt;

  const AuthLocalSessionRecord({
    required this.userId,
    required this.degradedMode,
    required this.refreshExpiresAt,
    required this.lastEvaluatedAt,
  });

  factory AuthLocalSessionRecord.fromMap(Map<String, Object?> map) {
    return AuthLocalSessionRecord(
      userId: map['user_id'] as String,
      degradedMode: SessionMode.fromWire(map['degraded_mode'] as String?),
      refreshExpiresAt: map['refresh_expires_at'] as int,
      lastEvaluatedAt: map['last_evaluated_at'] as int,
    );
  }

  Map<String, Object?> toMap() => {
    'id': 1,
    'user_id': userId,
    'degraded_mode': degradedMode.wire,
    'refresh_expires_at': refreshExpiresAt,
    'last_evaluated_at': lastEvaluatedAt,
  };
}
