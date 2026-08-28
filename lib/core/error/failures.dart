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

  /// Id de la fiche qui porte DÉJÀ ce numéro — la garde le connaît, et sans
  /// lui l'UI ne peut que le redeviner par une recherche plus large que la
  /// comparaison qui a refusé l'écriture (donc proposer la mauvaise fiche).
  /// `null` seulement pour les émetteurs historiques qui ne le fournissent pas.
  final String? existingParentId;

  const DuplicateParentPhoneFailure(this.phoneNumber, {this.existingParentId})
    : super('Un tuteur avec le numéro $phoneNumber existe déjà.');

  @override
  List<Object?> get props => [message, phoneNumber, existingParentId];
}

/// Cause typée servie par le serveur dans l'enveloppe `ApiErrorResponse`.
///
/// **Le statut seul ne suffit pas à décider.** Deux 400 peuvent appeler des
/// conduites opposées : un champ mal rempli se corrige sur place, tandis qu'une
/// règle métier refusée — « cette année académique existe déjà » — demande de
/// purger le brouillon et de revenir en arrière. Sans ce code, les deux
/// arrivaient à l'écran sous le même « Invalid request data ».
///
/// Se brancher sur la valeur, **jamais sur le message** : celui-ci est rédigé
/// pour être lu par un humain et changera sans préavis.
///
/// Miroir de `ApiErrorCode` côté serveur. [unknown] est le repli obligatoire :
/// le catalogue serveur peut grandir sans release client, et une valeur inédite
/// doit dégrader vers le comportement générique du statut HTTP, pas faire
/// échouer le parsing.
enum ApiErrorCode {
  businessRule('BUSINESS_RULE'),
  validation('VALIDATION'),
  unauthenticated('UNAUTHENTICATED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  duplicate('DUPLICATE'),
  concurrentModification('CONCURRENT_MODIFICATION'),
  unprocessable('UNPROCESSABLE'),
  tooManyRequests('TOO_MANY_REQUESTS'),
  internalError('INTERNAL_ERROR'),

  /// Code servi que ce client ne connaît pas encore.
  unknown('');

  const ApiErrorCode(this.wire);

  final String wire;

  /// Résout un code servi, ou [unknown] — jamais une exception.
  static ApiErrorCode fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) return unknown;
    for (final code in values) {
      if (code != unknown && code.wire == wire) return code;
    }
    return unknown;
  }
}

/// Ce qu'une réponse d'erreur du serveur porte au-delà de son statut.
///
/// Mixin plutôt que classe : les failles typées doivent rester **assignables à
/// leur famille historique** ([ValidationFailure], [ServerFailure]…), sur
/// laquelle une vingtaine de repositories filtrent déjà. Un appelant qui ignore
/// le code continue de fonctionner ; celui qui en a besoin teste le sous-type.
mixin ApiErrorDetails on Failure {
  ApiErrorCode get code;

  /// Message rédigé par le serveur, à afficher tel quel quand il est plus précis
  /// que le libellé générique de l'écran — un 422 nomme le niveau fautif.
  /// Jamais à tester : il change sans préavis.
  String? get serverMessage;

  /// Référence d'incident, posée **uniquement** sur les pannes serveur et
  /// écrite au même instant dans le journal du serveur. C'est le « code
  /// incident » que l'utilisateur cite au support ; en fabriquer un côté client
  /// donnerait une référence que rien ne permettrait de retrouver.
  String? get incidentId;
}

/// 400 ou 422 portant le code typé du serveur.
///
/// Reste une [ValidationFailure] : tout ce qui filtrait dessus continue de la
/// voir. Ce qu'elle ajoute, c'est de quoi distinguer les deux 400 qui ne
/// se traitent pas pareil (cf. [ApiErrorCode]).
class ApiValidationFailure extends ValidationFailure with ApiErrorDetails {
  @override
  final ApiErrorCode code;

  @override
  final String? serverMessage;

  @override
  String? get incidentId => null;

  const ApiValidationFailure({
    required this.code,
    this.serverMessage,
    String message = 'Invalid request data',
  }) : super(message);

  @override
  List<Object?> get props => [message, code, serverMessage];
}

/// 5xx portant le code typé et, quand le serveur en pose une, la référence
/// d'incident à afficher et à copier.
class ApiServerFailure extends ServerFailure with ApiErrorDetails {
  @override
  final ApiErrorCode code;

  @override
  final String? serverMessage;

  @override
  final String? incidentId;

  const ApiServerFailure({
    this.code = ApiErrorCode.internalError,
    this.serverMessage,
    this.incidentId,
    String message = 'Server error',
  }) : super(message);

  @override
  List<Object?> get props => [message, code, serverMessage, incidentId];
}

/// HTTP 429 — cadence dépassée.
///
/// Distincte de [NetworkFailure] et de [ServerFailure] parce que le geste
/// qu'elle appelle l'est : ni l'une ni l'autre, il faut **attendre**. Proposer
/// « Réessayer » ici invite à reproduire exactement ce qui vient d'être refusé.
class TooManyRequestsFailure extends Failure with ApiErrorDetails {
  @override
  ApiErrorCode get code => ApiErrorCode.tooManyRequests;

  @override
  final String? serverMessage;

  @override
  String? get incidentId => null;

  /// Délai annoncé par l'en-tête `Retry-After`, quand le serveur en pose un.
  final Duration? retryAfter;

  const TooManyRequestsFailure({
    this.retryAfter,
    this.serverMessage,
    String message = 'Too many requests',
  }) : super(message);

  @override
  List<Object?> get props => [message, retryAfter, serverMessage];
}

/// L'école de la session n'a **pas encore été paramétrée** : le référentiel a
/// bien été pullé, le serveur a répondu, et il n'y a toujours aucune année
/// académique courante.
///
/// Ce n'est ni une panne ni une absence de réseau — c'est un état légitime du
/// produit, celui d'un établissement fraîchement souscrit. Sans ce type, il
/// remontait en [ServerFailure] et le splash affichait une erreur réseau avec un
/// bouton « Réessayer » qui ne pouvait par construction jamais aboutir : rien
/// dans le geste de réessayer ne crée une année scolaire.
///
/// L'issue n'est pas de réessayer, c'est d'ouvrir l'assistant de configuration —
/// et seulement pour qui détient `school.provisioning.write`.
class SchoolNotProvisionedFailure extends Failure {
  const SchoolNotProvisionedFailure([
    super.message = 'School has not been provisioned yet',
  ]);
}
