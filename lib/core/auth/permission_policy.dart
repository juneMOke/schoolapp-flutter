import 'package:school_app_flutter/core/auth/permissions.dart';

/// Politique d'accès du client — **une seule fonction**, pure, hors de tout
/// framework (ADR-014 §2.9/§5).
///
/// Le registre de modules, les gardes d'action et la garde de route appellent
/// tous celle-ci. Deux politiques parallèles produiraient tôt ou tard une tuile
/// visible dont la route est fermée, ou l'inverse ; l'invariant vaut côté
/// client comme côté serveur.
///
/// **Ce n'est pas une frontière de sécurité.** Le serveur re-dérive
/// l'autorisation à chaque requête et ne fait aucune confiance à ce que le
/// client croit pouvoir faire : masquer ici relève de l'ergonomie, pas de la
/// protection. Un bouton oublié produit un 403, pas une faille.
///
/// [requires] — permissions exigées, référencées par [Perm] (vocabulaire de
/// l'APK). [permissions] — ensemble effectif de la session, en valeurs sur le
/// fil : un ensemble **ouvert**, dont les entrées inconnues du client sont
/// simplement sans effet ici. [requiresAll] — conjonction plutôt que
/// disjonction ; utile là où un point d'entrée franchit deux frontières
/// d'autorité en un appel (encaisser *et* sceller le reçu, §2.11).
///
/// **[permissions] à `null` = ensemble inconnu, et l'interface se ferme.**
/// C'est une asymétrie assumée avec la boucle de synchronisation, qui, elle,
/// TIRE sur inconnu : les deux choix vont dans le sens du moindre dommage.
/// Masquer ne coûte qu'un écran explicite avec une sortie ; ne pas tirer
/// couperait la synchronisation sans recours, et le serveur reste de toute
/// façon la seule frontière réelle.
///
/// **Fail-closed, y compris sur [requires] vide.** Une exigence vide rend
/// `false`, dans les deux modes. C'est le contraire de ce que `every` ferait
/// naturellement sur une liste vide (`true`), et c'est délibéré : une exigence
/// vide est presque toujours une déclaration oubliée, et un oubli doit refuser.
/// Ce qui est réellement public ne s'appelle pas ici — on ne le garde pas.
bool canAccess({
  required Iterable<Perm> requires,
  required Iterable<String>? permissions,
  bool requiresAll = false,
}) {
  if (permissions == null || requires.isEmpty) return false;
  // Matérialisé en Set : `permissions` est souvent une List (l'état de session
  // la porte ainsi), et une conjonction de deux exigences la parcourrait deux
  // fois. Le coût reste négligeable — le catalogue tient en quelques dizaines
  // d'entrées — mais la fonction est appelée à chaque build de chaque tuile.
  final held = permissions.toSet();
  return requiresAll
      ? requires.every((p) => held.contains(p.wire))
      : requires.any((p) => held.contains(p.wire));
}
