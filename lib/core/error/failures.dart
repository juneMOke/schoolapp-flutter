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

/// La requête est partie mais son sort est **inconnu** : dépassement de délai
/// de réception, ou connexion rompue après l'envoi. Le serveur peut l'avoir
/// exécutée intégralement.
///
/// Distincte de [NetworkFailure], qui signale une absence de réseau — donc une
/// requête qui n'a rien pu produire. La différence n'est pas cosmétique : sur
/// une opération **non idempotente**, rejouer une [NetworkFailure] est sans
/// risque, rejouer une [UncertainOutcomeFailure] duplique l'effet.
///
/// Cas concret de l'éditique : le relevé (RL) et le quitus (QT) consomment un
/// numéro de séquence **avant** que le serveur ne rende le PDF, et ne sont
/// jamais archivés. Le rendu peut dépasser le `receiveTimeout` de 12 s alors
/// que la pièce a bien été produite et son numéro brûlé. Proposer « Réessayer »
/// là-dessus fabrique un doublon numéroté, invisible côté client.
class UncertainOutcomeFailure extends Failure {
  const UncertainOutcomeFailure([super.message = 'Request outcome is unknown']);
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

/// L'imprimante thermique n'a pas pu recevoir le ticket, et **la raison est
/// actionnable par le caissier**.
///
/// Les quatre cas sont distincts parce que le geste qu'ils appellent l'est :
/// accorder une permission, allumer le Bluetooth, choisir une imprimante,
/// rallumer la machine. Un message unique (« impression impossible ») ferait
/// chercher au guichet la mauvaise cause.
///
/// ⚠️ Aucun de ces échecs n'est une perte : le versement est déjà écrit
/// localement quand le ticket s'imprime. Ils ne coûtent que le papier, et le
/// repli PDF reste ouvert.
enum ThermalPrinterProblem {
  /// `BLUETOOTH_CONNECT` non accordée (Android 12+). Le plugin ne la demande
  /// pas lui-même — c'est l'application qui doit le faire.
  permissionDenied,

  /// L'adaptateur Bluetooth de la tablette est éteint.
  bluetoothOff,

  /// Aucune imprimante retenue pour cette tablette, ou celle qui l'était n'est
  /// plus appairée.
  noPrinterSelected,

  /// Appairée mais injoignable : éteinte, hors de portée, ou déjà connectée à
  /// un autre appareil.
  unreachable,
}

class ThermalPrinterFailure extends Failure {
  final ThermalPrinterProblem problem;

  const ThermalPrinterFailure(this.problem, [super.message = 'Printer error']);

  @override
  List<Object?> get props => [message, problem];
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
