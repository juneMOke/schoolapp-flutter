import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Invalid email or password',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid request data']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication error']);
}

/// HTTP 409 — conflit d'état côté serveur. Deux usages :
/// - verrou optimiste périmé au flush de l'outbox (version/last-write-wins) → le
///   moteur de synchro déclenche un refetch + rejeu ;
/// - double-booking d'un créneau d'emploi du temps (enseignant ou classe).
class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflict']);
}

/// Doublon de numéro de téléphone parent — contrainte APPLICATIVE (DAO),
/// détectée avant toute écriture. Purement local, jamais de conflit réseau
/// (distinct de [ConflictFailure], réservée aux 2 usages HTTP 409 ci-dessus).
class DuplicateParentPhoneFailure extends Failure {
  final String phoneNumber;
  const DuplicateParentPhoneFailure(this.phoneNumber)
    : super('Un tuteur avec le numéro $phoneNumber existe déjà.');

  @override
  List<Object?> get props => [message, phoneNumber];
}
