import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/dashboard_period_preference.dart';

/// [DashboardPeriodPreference] rangée dans le stockage sécurisé, faute d'autre
/// magasin de préférences sur toutes les plateformes (cf.
/// `SidebarPreferenceStore`) ; la valeur n'a rien de secret.
///
/// La clé porte l'utilisateur **et** l'école : deux comptes sur une tablette
/// partagée gardent chacun leur choix.
class DashboardPeriodStore implements DashboardPeriodPreference {
  static const _prefix = 'ui.boutique.dashboard_period';

  final FlutterSecureStorage _storage;
  final CurrentUserContext _currentUser;

  const DashboardPeriodStore({
    required FlutterSecureStorage storage,
    required CurrentUserContext currentUser,
  }) : _storage = storage,
       _currentUser = currentUser;

  String get _key => '$_prefix.${_currentUser.ownerKey}';

  @override
  Future<DashboardPeriod?> read() async {
    try {
      return DashboardPeriod.fromStorage(await _storage.read(key: _key));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(DashboardPeriod period) async {
    try {
      await _storage.write(key: _key, value: period.storageKey);
    } catch (_) {}
  }
}
