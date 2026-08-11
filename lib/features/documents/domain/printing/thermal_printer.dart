import 'package:equatable/equatable.dart';

/// Une imprimante thermique **déjà appairée** avec la tablette.
///
/// Le parc ETEELO est appairé une fois pour toutes dans les réglages Android,
/// à la mise en service. L'application ne découvre donc **jamais** : elle lit la
/// liste des appareils liés (`bondedDevices`). Cette décision garde
/// `ACCESS_FINE_LOCATION` hors du périmètre — la permission la plus mal vécue
/// par les utilisateurs, et la plus difficile à justifier pour une caisse
/// d'école.
///
/// ⚠️ Elle ne dispense **pas** de `BLUETOOTH_SCAN` pour autant : le plugin
/// annule la découverte avant d'ouvrir la liaison, et cet appel en relève. Le
/// manifeste la déclare donc, avec `neverForLocation`.
class ThermalPrinter extends Equatable {
  /// Nom annoncé par l'appareil, tel qu'il apparaît dans les réglages Android.
  final String name;

  /// Adresse MAC — l'identité stable. C'est elle qu'on retient, jamais le nom :
  /// deux NT-8003DD d'un même établissement portent le même nom d'usine.
  final String macAddress;

  const ThermalPrinter({required this.name, required this.macAddress});

  /// Lit le format rendu par le canal natif : `"<nom>#<MAC>"`.
  ///
  /// Rend `null` sur une ligne qui ne porte pas d'adresse. Le nom, lui, peut
  /// être vide : un appareil sans nom reste joignable, et le taire vaut mieux
  /// que d'écarter une imprimante qui fonctionne.
  static ThermalPrinter? tryParse(String raw) {
    final separator = raw.lastIndexOf('#');
    if (separator < 0) return null;

    final mac = raw.substring(separator + 1).trim();
    if (mac.isEmpty) return null;

    return ThermalPrinter(
      name: raw.substring(0, separator).trim(),
      macAddress: mac,
    );
  }

  @override
  List<Object?> get props => [name, macAddress];
}
