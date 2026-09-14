import 'package:school_app_flutter/core/database/tenant/device_database.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';

/// Les curseurs qui vivent avec l'APPAREIL (MULTI_ECOLE_PLAN.md §10.2) : ceux
/// du catalogue éditique, dont l'index est au niveau du poste.
///
/// Un type à part pour que la DI ne les confonde pas avec ceux de l'école,
/// `getIt<SyncMetaDao>()` : une purge de l'index rembobinerait sinon le
/// curseur d'un autre fichier, et laisserait le sien en avance sur un index
/// vide.
class DeviceSyncMetaDao extends SyncMetaDao {
  DeviceSyncMetaDao(DeviceDatabase device) : super(device.db);
}
