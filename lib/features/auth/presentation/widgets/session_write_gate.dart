import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Gel des écritures en session READ_ONLY (ADR-010 D-08, J21+ / triche horloge).
///
/// Enveloppe un CTA d'écriture métier (bouton, FAB, tuile d'action…) : quand
/// `sessionMode.blocksWrites`, le CTA devient inerte (tap ignoré), estompé, et
/// un appui long affiche le rappel « lecture seule ». Wrapper plutôt que flag
/// sur `EteeloButton` : les CTA d'écriture sont hétérogènes (DS **et**
/// `FilledButton`/`FloatingActionButton` bruts) — un point d'entrée unique
/// couvre tout.
///
/// La consultation n'est jamais gelée : n'envelopper QUE les déclencheurs
/// d'écriture (création/modification métier), pas la navigation ni les
/// recherches. READ_ONLY est une politique UX — la frontière d'intégrité reste
/// le serveur (D-05) ; un CTA oublié produit une écriture valide et attribuée,
/// pas une faille.
///
/// Sans [AuthBloc] dans l'arbre (tests widget de pages métier montées seules),
/// le gate est transparent.
class SessionWriteGate extends StatelessWidget {
  const SessionWriteGate({super.key, required this.child});

  final Widget child;

  /// Opacité du CTA gelé — assez marquée pour lire « désactivé », assez
  /// présente pour que l'appui long (tooltip d'explication) reste invitant.
  static const double _frozenOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final bloc = _maybeAuthBloc(context);
    if (bloc == null) return child;

    return BlocBuilder<AuthBloc, AuthState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          previous.sessionMode != current.sessionMode,
      builder: (context, state) {
        if (!state.sessionMode.blocksWrites) return child;
        final l10n = AppLocalizations.of(context);
        // ExcludeFocus en plus de l'IgnorePointer : ce dernier ne retire le
        // sous-arbre que du hit-testing POINTEUR — sans lui, Tab + Entrée sur
        // clavier physique (ou le bouton « send » du clavier virtuel via
        // onSubmitted) activerait encore le CTA gelé (revue adversariale). Il
        // éjecte aussi le focus déjà posé (champ en cours de frappe au moment
        // de la bascule READ_ONLY).
        final frozen = ExcludeFocus(
          child: IgnorePointer(
            child: Opacity(opacity: _frozenOpacity, child: child),
          ),
        );
        if (l10n == null) return frozen;
        return Tooltip(
          message: l10n.sessionReadOnlyBanner,
          triggerMode: TooltipTriggerMode.longPress,
          child: frozen,
        );
      },
    );
  }

  /// Lecture ponctuelle (sans abonnement) pour les gardes impératives hors
  /// widget — ex. bloquer un seed de brouillon au tap. Sans [AuthBloc] dans
  /// l'arbre (tests de pages métier montées seules) → `false` (pas de gel).
  static bool blocksWritesOf(BuildContext context) =>
      _maybeAuthBloc(context)?.state.sessionMode.blocksWrites ?? false;

  /// Variante builder : expose `blocksWrites` pour ne geler qu'UNE action d'un
  /// widget composé — ex. un footer primaire+secondaire dont le secondaire est
  /// une navigation (Annuler/Fermer) qui doit RESTER libre : geler tout le
  /// footer piégerait l'utilisateur dans le dialog.
  static Widget builder({
    Key? key,
    required Widget Function(BuildContext context, bool blocksWrites) builder,
  }) => _SessionWriteGateBuilder(key: key, builder: builder);

  static AuthBloc? _maybeAuthBloc(BuildContext context) {
    // Détection d'absence, pas gestion d'erreur : flutter_bloc lève un
    // `FlutterError` (relayé de ProviderNotFoundException) quand aucun
    // provider n'est monté — cas légitime des arbres de test de pages métier.
    // On n'attrape QUE ce cas : toute autre erreur (DI cassée, create qui
    // jette) doit remonter — sinon le gel entier serait silencieusement
    // désactivé sans signal.
    try {
      return BlocProvider.of<AuthBloc>(context);
    } on FlutterError {
      return null;
    }
  }
}

class _SessionWriteGateBuilder extends StatelessWidget {
  const _SessionWriteGateBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool blocksWrites) builder;

  @override
  Widget build(BuildContext context) {
    final bloc = SessionWriteGate._maybeAuthBloc(context);
    if (bloc == null) return builder(context, false);
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          previous.sessionMode != current.sessionMode,
      builder: (context, state) =>
          builder(context, state.sessionMode.blocksWrites),
    );
  }
}
