/// Ce que l'application doit pouvoir faire d'une permission Bluetooth.
///
/// ## Pourquoi cette pièce existe séparément
///
/// Le canal natif de `print_bluetooth_thermal` sait **constater**
/// `BLUETOOTH_CONNECT`, pas la **demander** : son code de sollicitation existe
/// mais est commenté dans le source. Sans ce complément, une tablette Android 12
/// ou plus récente n'aurait aucun chemin vers la permission depuis
/// l'application — le caissier devrait la trouver seul dans les réglages
/// système, et tout appel au canal pendrait indéfiniment en attendant.
///
/// C'est la **première permission runtime du dépôt** : le manifeste ne
/// déclarait que `INTERNET` avant ce lot.
abstract class ThermalPrinterPermission {
  /// Constate l'état des **deux** permissions, sans rien demander.
  ///
  /// ⚠️ Existe parce que le canal natif est **aveugle à `BLUETOOTH_SCAN`** : son
  /// `isPermissionBluetoothGranted` ne teste que `BLUETOOTH_CONNECT`
  /// (`PrintBluetoothThermalPlugin.kt:59`). S'y fier seul a déjà produit la
  /// panne exacte que voici : `CONNECT` accordée, `SCAN` jamais demandée,
  /// `ensureReady()` qui donne le feu vert, la liste des appairées qui
  /// s'affiche — puis l'impression qui échoue en annonçant une imprimante
  /// injoignable. Constater à moitié est pire que ne pas constater : ça déplace
  /// l'échec loin de sa cause.
  ///
  /// Ne lève jamais : sur une plateforme sans canal (test, bureau), rend
  /// `false`.
  Future<bool> isGranted();

  /// Sollicite la permission et rend son état après coup.
  ///
  /// Ne lève jamais : un refus est une réponse, pas une panne.
  Future<ThermalPrinterPermissionState> request();

  /// Ouvre la fiche de l'application dans les réglages système.
  ///
  /// Seul recours quand l'utilisateur a refusé **définitivement** : Android ne
  /// réaffiche alors plus jamais la boîte de dialogue, et un bouton qui
  /// redemanderait ne produirait plus rien du tout.
  Future<void> openSettings();
}

enum ThermalPrinterPermissionState {
  granted,

  /// Refusée cette fois — redemander a du sens.
  denied,

  /// Refusée définitivement (ou verrouillée par une politique d'entreprise) :
  /// seul un passage par les réglages peut la débloquer. La distinction est ce
  /// qui évite de proposer un bouton qui ne peut plus rien faire.
  permanentlyDenied,
}
