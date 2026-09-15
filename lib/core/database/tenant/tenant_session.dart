import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/database/tenant/offline_database_files.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_database.dart';

/// Attache et détache l'école de la session (MULTI_ECOLE_PLAN.md §10.2).
abstract interface class TenantSwitch {
  /// Attache le fichier de [schoolId] ; sans effet si c'est déjà lui.
  ///
  /// Un identifiant vide DÉTACHE : une session sans école n'écrit dans aucune —
  /// surtout pas dans celle de la session précédente.
  ///
  /// Lève si le fichier ne s'ouvre pas.
  Future<void> attach(String schoolId);

  /// Détache l'école courante.
  Future<void> detach();
}

/// Rien à attacher : une base unique porte l'appareil et l'école (tests, socle
/// monté avec une base injectée).
class PinnedTenantSession implements TenantSwitch {
  const PinnedTenantSession();

  @override
  Future<void> attach(String schoolId) async {}

  @override
  Future<void> detach() async {}
}

/// Ce qui se rejoue après chaque attachement — une reprise de données qui
/// doit précéder le premier flush de l'école.
typedef TenantAttachedHook = Future<void> Function();

/// L'école de la session, sur les fichiers du poste.
class TenantSession implements TenantSwitch {
  final TenantDatabase _tenant;
  final OfflineDatabaseFiles _files;
  final Database _device;
  final List<TenantAttachedHook> _onAttached;

  /// Fichiers déjà ouverts, et gardés ouverts. Une bascule de retour est
  /// instantanée, et une transaction encore en vol sur le fichier d'une école
  /// détachée se termine là où elle a commencé au lieu d'échouer sur un
  /// fichier fermé.
  final Map<String, Database> _opened = {};

  /// Attachements et détachements passent l'un après l'autre : le démarrage
  /// et le tic de fraîcheur attachent tous deux, et deux ouvertures du même
  /// fichier en parallèle en feraient deux connexions.
  Future<void> _tail = Future<void>.value();

  TenantSession({
    required TenantDatabase tenant,
    required OfflineDatabaseFiles files,
    required Database device,
    List<TenantAttachedHook> onAttached = const [],
  }) : _tenant = tenant,
       _files = files,
       _device = device,
       _onAttached = onAttached;

  @override
  Future<void> attach(String schoolId) => _serialized(() async {
    if (schoolId.isEmpty) {
      _tenant.detach();
      return;
    }
    if (_tenant.isAttached && _tenant.schoolId == schoolId) return;
    final database = _opened[schoolId] ??= await _files.openSchool(
      schoolId,
      device: _device,
    );
    _tenant.attach(schoolId, database);
    for (final hook in _onAttached) {
      try {
        await hook();
      } catch (_) {
        // Une reprise qui échoue se rejouera au prochain attachement ; elle
        // ne doit pas refuser la session.
      }
    }
  });

  @override
  Future<void> detach() => _serialized(() async => _tenant.detach());

  Future<void> _serialized(Future<void> Function() body) {
    final run = _tail.then((_) => body());
    // Un attachement qui échoue ne bloque pas les suivants.
    _tail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }
}
