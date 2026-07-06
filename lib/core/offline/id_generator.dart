import 'package:uuid/uuid.dart';

/// Génère les identifiants client (UUID v4, RNG cryptographique par défaut du
/// paquet `uuid`). Injecté pour rester déterministe/mockable en test.
///
/// Ces UUID sont générés côté client et honorés par le serveur (idempotence) :
/// `student.id`, `enrollment.id`, `payment.client_uuid`, `disciplinary_case.id`,
/// id des entrées d'outbox, etc.
class IdGenerator {
  final Uuid _uuid;

  const IdGenerator(this._uuid);

  String newId() => _uuid.v4();
}
