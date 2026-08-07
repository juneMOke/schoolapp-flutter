import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';

/// Qui a le droit de détenir des pièces scellées sur cette tablette (RG-012-4).
///
/// ## Une liste blanche, jamais une exclusion
///
/// La tentation serait d'écrire « tout sauf enseignant ». Elle serait fausse
/// deux fois. D'abord parce que le rôle **retombe sur chaîne vide** au démarrage
/// à froid, et qu'une chaîne vide n'est pas « enseignant » : la garde serait
/// donc ouverte précisément au moment où l'identité n'est pas encore établie.
/// Ensuite parce qu'un rôle ajouté demain serait admis sans que personne ne l'ait
/// décidé.
///
/// La liste est donc positive, et ce qu'elle ne nomme pas est refusé — y compris
/// l'inconnu, l'absent et le vide.
abstract final class EditiqueCacheEntitlement {
  /// Les six profils internes de l'établissement. Les trois exclus — enseignant,
  /// parent, élève — n'ont aucune raison de conserver des pièces scellées sur
  /// leur appareil.
  static const Set<String> allowedRoles = {
    'SUPER_ADMIN',
    'DIRECTOR',
    'SECRETARY',
    'ACCOUNTANT',
    'ACADEMIC_ADMIN',
    'DISCIPLINE_SUPERVISOR',
  };

  /// Vrai si ce rôle peut détenir des pièces.
  ///
  /// La casse est normalisée avant comparaison : rien, côté client, ne garantit
  /// celle que le serveur envoie — `UserModel.fromJson` fait un cast brut. Sans
  /// cette normalisation, un changement de sérialisation ouvrirait ou fermerait
  /// la garde en silence.
  static bool isAllowed(String? role) {
    final normalized = role?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return false;
    return allowedRoles.contains(normalized);
  }
}

/// Ce que le cache a besoin de savoir de la session courante, et rien d'autre.
///
/// Volontairement minuscule : le cache vit en couche data, il n'a pas de
/// `BuildContext` et n'a aucune raison de connaître l'authentification. Il pose
/// une question, il reçoit un oui ou un non.
abstract interface class EditiqueCacheAccess {
  /// Vrai si la session courante peut détenir des pièces scellées.
  Future<bool> isEntitled();
}

/// Réponse lue dans la base locale.
///
/// `auth_local_user` fait autorité hors ligne, et c'est ce qui rend cette garde
/// **fail-closed par construction** : la ligne n'est écrite que par un login
/// online réussi, donc son absence — session jamais ouverte, base illisible,
/// compte effacé — se lit `null`, et `null` est un refus. Le secure storage,
/// lui, rend une chaîne vide dans ces cas-là ; il aurait fallu s'en méfier.
class LocalEditiqueCacheAccess implements EditiqueCacheAccess {
  final AuthLocalDao _authLocalDao;

  const LocalEditiqueCacheAccess(this._authLocalDao);

  @override
  Future<bool> isEntitled() async {
    try {
      final user = await _authLocalDao.getSessionUser();
      return EditiqueCacheEntitlement.isAllowed(user?.role);
    } catch (_) {
      // Une base qu'on ne sait pas lire ne prouve aucun droit.
      return false;
    }
  }
}
