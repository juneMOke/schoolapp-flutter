import 'package:permission_handler/permission_handler.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';

/// Le seul fichier du dépôt qui touche `permission_handler`.
///
/// Android 11 et antérieurs n'ont ni `BLUETOOTH_CONNECT` ni `BLUETOOTH_SCAN` :
/// les permissions y sont accordées à l'installation, et `permission_handler`
/// rend `granted` sans rien afficher. Aucune ramification de version n'est donc
/// nécessaire ici — c'est le paquet qui la porte.
class PermissionHandlerThermalPermission implements ThermalPrinterPermission {
  const PermissionHandlerThermalPermission();

  @override
  Future<bool> isGranted() async {
    try {
      // Les deux, sans exception : `BLUETOOTH_SCAN` conditionne l'ouverture de
      // la liaison autant que `BLUETOOTH_CONNECT`, même si elle ne sert jamais
      // à scanner. Sur Android ≤ 11, `permission_handler` rend `granted` pour
      // les deux sans rien afficher.
      return await Permission.bluetoothConnect.isGranted &&
          await Permission.bluetoothScan.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ThermalPrinterPermissionState> request() async {
    try {
      // ⚠️ LES DEUX, en un seul geste. `BLUETOOTH_SCAN` n'est pas demandée
      // parce que nous scannerions — nous ne scannons jamais — mais parce que
      // le plugin appelle `cancelDiscovery()` sur le chemin de connexion, et
      // que cet appel en relève. Sans elle, la liaison RFCOMM ne s'ouvre pas.
      //
      // Android les range dans le même groupe (« Appareils à proximité ») :
      // une seule boîte de dialogue, une seule réponse de l'utilisateur, et
      // pas de cas réaliste où l'une est accordée sans l'autre. C'est ce qui
      // permet de ne PAS constater `BLUETOOTH_SCAN` séparément dans
      // `ThermalPrinterAdapter.ensureReady` — le canal natif, lui, ne sait
      // constater que `BLUETOOTH_CONNECT`.
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
      final granted = statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );
      if (granted) return ThermalPrinterPermissionState.granted;

      // `restricted` est le verrouillage par politique d'entreprise — le parc
      // ETEELO est sous Android Enterprise, donc le cas est réel. Comme un refus
      // définitif, il ne se lève pas depuis l'application.
      final blocked = statuses.values.any(
        (status) => status.isPermanentlyDenied || status.isRestricted,
      );
      if (blocked) return ThermalPrinterPermissionState.permanentlyDenied;

      return ThermalPrinterPermissionState.denied;
    } catch (_) {
      // Canal de plateforme absent (test, bureau) : traité comme un refus
      // ordinaire, jamais comme une panne — il n'y a rien à imprimer là.
      return ThermalPrinterPermissionState.denied;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {
      // Rien à faire de plus : l'utilisateur garde le chemin manuel.
    }
  }
}
