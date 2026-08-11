/// Le canal natif vers l'imprimante, réduit à ce dont l'application se sert.
///
/// **Cette abstraction n'est pas de la cérémonie.** Le paquet
/// `print_bluetooth_thermal` n'expose que des méthodes **statiques** : sans une
/// couture ici, la politique d'appel (délais, ordre des vérifications, mise en
/// correspondance des échecs) serait intestable, et c'est précisément là que
/// vivent les pièges du canal.
///
/// Ce fichier n'importe **pas** le paquet — c'est ce qui permet aux tests de
/// fournir un double sans embarquer un plugin de plateforme absent en test.
abstract class ThermalPrinterChannel {
  /// `BLUETOOTH_CONNECT` accordée ? Toujours vrai avant Android 12.
  ///
  /// ⚠️ Ne fait que **constater** : le canal natif a du code pour la demander,
  /// mais il est commenté. C'est donc à l'application de la solliciter.
  Future<bool> isPermissionGranted();

  /// L'adaptateur Bluetooth de la tablette est-il allumé ?
  Future<bool> isBluetoothEnabled();

  /// Appareils appairés, au format brut `"<nom>#<MAC>"`.
  Future<List<String>> pairedDevices();

  /// Ouvre la liaison RFCOMM. Rend `false` si l'imprimante ne répond pas.
  Future<bool> connect(String macAddress);

  /// Écrit le flux. **Un seul appel par ticket** — voir `ThermalPrinterPort`.
  Future<bool> writeBytes(List<int> bytes);

  /// Ferme la liaison. Ne lève jamais.
  Future<void> disconnect();
}
