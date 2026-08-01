/// Résolution d'un `authorId` d'outbox en identité affichable.
///
/// La file ne connaît que des uids. Pour dire à l'enseignant « 4 écritures en
/// attente de Marie K. » plutôt que « en attente de 3f2a-… », il faut traduire
/// cet uid — et la seule source locale est la table `auth_local_user`, qui vit
/// dans `features/auth`.
///
/// D'où cette interface **dans le socle**, implémentée côté auth : même patron
/// que [SessionCredentialsProbe] et `RevocationEvaluator`, le socle `core/`
/// reste découplé de `features/auth`.
///
/// Ne renvoie que l'état civil, jamais le contenu des écritures : sur une
/// tablette partagée, un enseignant doit comprendre POURQUOI la file ne se vide
/// pas, sans rien apprendre du travail de son collègue.
abstract interface class OutboxAuthorDirectory {
  /// Identité connue localement pour [uid], ou `null` si ce compte n'a jamais
  /// ouvert de session sur cette tablette (cas possible : la file survit à un
  /// wipe de session, `auth_local_user` aussi, mais rien ne le garantit après
  /// une révocation).
  Future<OutboxAuthorIdentity?> identityOf(String uid);
}

/// État civil minimal d'un auteur d'écriture, tel que stocké localement.
class OutboxAuthorIdentity {
  final String firstName;
  final String lastName;

  const OutboxAuthorIdentity({required this.firstName, required this.lastName});

  /// Vrai si aucun des deux champs n'est exploitable pour l'affichage.
  bool get isBlank => firstName.trim().isEmpty && lastName.trim().isEmpty;
}
