import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Combien d'opérations d'argent dans une devise attendent encore, sur cette
/// tablette, d'être envoyées au serveur : versements, corrections, ventes
/// boutique, dépenses, paie et avances.
///
/// Tant qu'il en reste, la caisse ne se clôture pas (D2) : le serveur ne peut
/// pas compter ce qu'il n'a pas reçu, et la caissière déclarerait un reste qui
/// ne correspond pas à l'attendu. On compte **quel que soit leur jour** : un
/// fait d'une journée antérieure non clôturée pèse aussi sur le reste
/// d'aujourd'hui.
abstract class CashPendingProbe {
  Future<int> pendingFor(TreasuryCurrency currency);
}
