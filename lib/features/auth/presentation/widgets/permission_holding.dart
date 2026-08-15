import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';

/// Ce que la session détient vis-à-vis d'une exigence — **trois** états, jamais
/// deux.
///
/// [unknown] n'est pas [missing]. L'ensemble effectif reste `null` tant que la
/// couche auth ne l'a pas communiqué : session ouverte avant la migration qui a
/// introduit les permissions, amorçage, ou harnais de test sans `AuthBloc`.
/// `canAccess` répond `false` dans ce cas, délibérément — une exigence non
/// satisfaite doit refuser. Mais **expliquer** un écran vide par « votre compte
/// n'y a pas droit » sur cette seule base accuserait des comptes qui ont tous
/// les droits, et dont les données descendent normalement.
///
/// Le dépôt distingue déjà « absent » de « vide » à trois endroits — le tri-état
/// des permissions, « section absente » ≠ « section vide » dans le bundle
/// Inscription, et `AccueilNoAccessState.permissionsUnknown`. Même patron.
enum PermissionHolding {
  /// La session détient l'exigence.
  granted,

  /// La session ne la détient pas — un vide en aval s'explique par là.
  missing,

  /// L'ensemble n'a jamais été communiqué : on ne sait pas, donc on n'affirme
  /// rien. L'appelant retombe sur son message générique.
  unknown,
}

/// Lit l'état de détention **sans s'abonner**, pour un message qui se calcule
/// dans `build`.
///
/// S'appuie sur `PermissionGate` pour la tolérance à l'absence d'`AuthBloc`,
/// qui reste ainsi écrite en un seul endroit. Sans bloc dans l'arbre, le gate
/// laisse passer : ici cela vaut [PermissionHolding.unknown], jamais
/// [PermissionHolding.granted] — un harnais de test qui monte une page seule ne
/// doit pas faire dire à l'écran que le compte a des droits qu'on n'a pas lus.
PermissionHolding permissionHolding(
  BuildContext context,
  List<Perm> requires, {
  bool requiresAll = false,
}) {
  final bloc = PermissionGate.maybeBlocOf(context);
  final held = bloc?.state.permissions;
  if (held == null) return PermissionHolding.unknown;
  // Exigence vide : `canAccess` refuse, délibérément — « une exigence vide est
  // presque toujours une déclaration oubliée, et un oubli doit refuser ». La
  // règle est juste pour une garde, qui **protège** ; elle s'inverse ici, où
  // l'on ne fait qu'**expliquer**. Un appelant qui oublie de déclarer son
  // exigence ferait dire à l'écran « votre profil n'a pas accès » sur la foi de
  // rien. Le repli sûr d'un helper d'explication est de se taire.
  if (requires.isEmpty) return PermissionHolding.unknown;
  return canAccess(
        requires: requires,
        permissions: held,
        requiresAll: requiresAll,
      )
      ? PermissionHolding.granted
      : PermissionHolding.missing;
}
