import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
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
}) => permissionHoldingOf(
  PermissionGate.maybeBlocOf(context)?.state.permissions,
  requires,
  requiresAll: requiresAll,
);

/// La même règle, **sans arbre** : à partir de l'ensemble brut.
///
/// Existe pour les appelants qui tiennent déjà l'état de session en main — un
/// `buildWhen`, un `listenWhen`, un `State` qui décide d'émettre une lecture.
/// Sans elle, chacun réécrivait « inconnu ne vaut pas refusé » pour son compte,
/// et c'est exactement la divergence qui a produit le défaut : la garde à deux
/// états d'un côté, le tri-état de l'autre, sur le même droit et le même écran.
PermissionHolding permissionHoldingOf(
  Iterable<String>? permissions,
  List<Perm> requires, {
  bool requiresAll = false,
}) {
  if (permissions == null) return PermissionHolding.unknown;
  // Exigence vide : `canAccess` refuse, délibérément — « une exigence vide est
  // presque toujours une déclaration oubliée, et un oubli doit refuser ». La
  // règle est juste pour une garde, qui **protège** ; elle s'inverse ici, où
  // l'on ne fait qu'**expliquer**. Un appelant qui oublie de déclarer son
  // exigence ferait dire à l'écran « votre profil n'a pas accès » sur la foi de
  // rien. Le repli sûr d'un helper d'explication est de se taire.
  if (requires.isEmpty) return PermissionHolding.unknown;
  return canAccess(
        requires: requires,
        permissions: permissions,
        requiresAll: requiresAll,
      )
      ? PermissionHolding.granted
      : PermissionHolding.missing;
}

/// Le pendant **abonné** de [permissionHolding] : trois états, et qui suit les
/// changements de droits en séance.
///
/// La matrice avait un trou. `PermissionGate` s'abonne mais ne connaît que deux
/// états — il ferme sur un ensemble inconnu, ce qui est le bon réflexe pour une
/// garde. [permissionHolding] distingue les trois états mais ne s'abonne pas :
/// lu dans un `build` extérieur, son verdict reste figé pour la vie de l'écran.
/// Une zone de résultats a besoin des deux à la fois — expliquer un vide sans
/// accuser un compte au hasard, **et** cesser de l'expliquer dès que l'ensemble
/// arrive.
///
/// Le `buildWhen` compare la **décision**, pas les ensembles : un droit qui
/// change ailleurs dans le catalogue ne reconstruit rien, et la comparaison n'a
/// pas à se prononcer sur les doublons d'une liste.
///
/// Sans `AuthBloc` dans l'arbre — harnais de test qui monte une page seule — le
/// builder reçoit [PermissionHolding.unknown], jamais `granted` : même
/// convention que [permissionHolding].
class PermissionHoldingBuilder extends StatelessWidget {
  const PermissionHoldingBuilder({
    super.key,
    required this.requires,
    required this.builder,
    this.requiresAll = false,
  });

  final List<Perm> requires;
  final bool requiresAll;
  final Widget Function(BuildContext context, PermissionHolding holding)
  builder;

  PermissionHolding _holdingOf(AuthState state) => permissionHoldingOf(
    state.permissions,
    requires,
    requiresAll: requiresAll,
  );

  @override
  Widget build(BuildContext context) {
    final bloc = PermissionGate.maybeBlocOf(context);
    if (bloc == null) return builder(context, PermissionHolding.unknown);
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          _holdingOf(previous) != _holdingOf(current),
      builder: (context, state) => builder(context, _holdingOf(state)),
    );
  }
}
