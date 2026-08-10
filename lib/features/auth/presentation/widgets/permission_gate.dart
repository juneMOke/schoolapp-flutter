import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';

/// Masque un déclencheur d'écriture que la session n'a pas le droit d'utiliser
/// (ADR-014 §2.5).
///
/// Frère de `SessionWriteGate`, et la nuance entre les deux est le geste :
/// celui-ci **masque**, l'autre **gèle**. Deux causes différentes, deux formes
/// différentes — un CTA estompé dit « pas maintenant » (session en lecture
/// seule, le droit reviendra), un CTA absent dit « pas vous ». Les confondre
/// rendrait les deux illisibles. Ils se composent : une action peut être gardée
/// par la permission **et** gelée par le mode de session.
///
/// **Ce n'est pas une frontière de sécurité.** Le serveur re-dérive
/// l'autorisation à chaque requête ; masquer relève de l'ergonomie. Un CTA
/// oublié produit un 403, pas une faille — mais sur les écritures qui partent
/// par l'outbox, ce 403 est classé TERMINAL : la saisie est alors perdue, ce
/// qui rend le masquage nettement moins cosmétique qu'il n'en a l'air.
///
/// Sans [AuthBloc] dans l'arbre, le gate est **transparent** — même convention
/// que `SessionWriteGate`. En production la racine le fournit toujours
/// (`main.dart`) ; le cas ne se présente que dans les harnais de test qui
/// montent une page métier seule.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.requires,
    required this.child,
    this.requiresAll = false,
    this.fallback,
  });

  /// Permissions exigées par l'action enveloppée.
  final List<Perm> requires;

  /// Conjonction — à réserver aux actions qui franchissent deux frontières
  /// d'autorité en un appel (encaisser *et* sceller le reçu).
  final bool requiresAll;

  final Widget child;

  /// Rendu de remplacement. Par défaut rien : une action qu'on n'a pas le droit
  /// de déclencher n'a pas à laisser de trace.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final bloc = _maybeAuthBloc(context);
    if (bloc == null) return child;

    return BlocBuilder<AuthBloc, AuthState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          !_sameSet(previous.permissions, current.permissions),
      builder: (context, state) {
        final allowed = canAccess(
          requires: requires,
          permissions: state.permissions,
          requiresAll: requiresAll,
        );
        return allowed ? child : (fallback ?? const SizedBox.shrink());
      },
    );
  }

  /// Lecture ponctuelle (sans abonnement) pour les gardes impératives hors
  /// widget — ex. refuser au tap l'ouverture d'une modale de saisie. Sans
  /// [AuthBloc] dans l'arbre → `true`, comme le rendu.
  static bool allows(
    BuildContext context,
    List<Perm> requires, {
    bool requiresAll = false,
  }) {
    final bloc = _maybeAuthBloc(context);
    if (bloc == null) return true;
    return canAccess(
      requires: requires,
      permissions: bloc.state.permissions,
      requiresAll: requiresAll,
    );
  }

  static bool _sameSet(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final held = b.toSet();
    return a.every(held.contains);
  }

  static AuthBloc? _maybeAuthBloc(BuildContext context) {
    // Détection d'absence, pas gestion d'erreur : flutter_bloc lève un
    // `FlutterError` quand aucun provider n'est monté — cas légitime des arbres
    // de test. On n'attrape QUE ce cas ; toute autre erreur doit remonter.
    try {
      return BlocProvider.of<AuthBloc>(context);
    } on FlutterError {
      return null;
    }
  }
}
