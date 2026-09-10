import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_list.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/relance_list_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Remet la liste de relance à la plateforme — **et l'oublie ensuite**.
///
/// Un écouteur, pas un widget visible : la seule affordance de l'écran est le
/// clic sur une ligne de simulation, et ce qui suit est du geste de plateforme.
class RelanceListDelivery extends StatelessWidget {
  final Widget child;

  const RelanceListDelivery({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      BlocListener<RelanceListCubit, RelanceListState>(
        listenWhen: (prev, curr) =>
            prev.document != curr.document || prev.failure != curr.failure,
        listener: _deliver,
        child: child,
      );

  static Future<void> _deliver(
    BuildContext context,
    RelanceListState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<RelanceListCubit>();
    final document = state.document;

    if (document != null) {
      await _handOver(context, document, l10n);
    } else if (state.failure case final failure?) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, message(failure, state, l10n));
    }

    // L'état se vide dans tous les cas : un document laissé là serait re-remis
    // à la reconstruction suivante, un message rejoué à chaque retour d'écran.
    if (!cubit.isClosed) cubit.acknowledge();
  }

  /// `Printing.layoutPdf` et non `sharePdf` : le partage système **écrit la
  /// pièce en clair dans le cache de l'application et ne l'efface jamais**, et
  /// cette liste porte des noms d'élèves. Le spouleur, lui, propose
  /// « enregistrer en PDF » sans laisser de copie derrière lui.
  static Future<void> _handOver(
    BuildContext context,
    RelanceList document,
    AppLocalizations l10n,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => document.bytes,
        // Le nom vient du serveur et n'est jamais réécrit : il porte le
        // périmètre réellement retenu.
        name: document.fileName,
      );
    } catch (_) {
      // Le canal natif peut manquer — binaire antérieur à la dépendance, ou
      // plateforme sans service d'impression. Le document est arrivé ; c'est le
      // geste qui a échoué, et le taire ne laisserait rien à l'écran.
      if (!context.mounted) return;
      AppSnackBar.showError(context, l10n.recouvrementRelanceListHandoffFailed);
    }
  }

  /// Ce qu'on dit au lecteur, dans **sa** langue quand c'est possible.
  ///
  /// ⚠️ **L'ordre compte.** Chaque refus typé est d'abord reconnu à son
  /// `detailCode` et rendu avec **nos** mots et **ses** chiffres ; à défaut
  /// seulement on retombe sur la phrase du serveur, qui porte l'information
  /// mais pas la langue de l'écran. Se brancher sur le code et non sur la
  /// phrase est la règle : celle-ci change sans préavis.
  @visibleForTesting
  static String message(
    Failure failure,
    RelanceListState state,
    AppLocalizations l10n,
  ) {
    // Le 429 n'est pas une panne : il dit d'ATTENDRE, et combien. Et il peut
    // venir d'un document lancé par quelqu'un d'autre — le permis de rendu est
    // partagé côté serveur — donc la phrase n'accuse pas l'utilisateur.
    if (failure is TooManyRequestsFailure) {
      return l10n.recouvrementRelanceListBusy(
        state.retryAfter?.inSeconds ?? 60,
      );
    }

    final cap = ReportLineCap.of(failure);
    if (cap != null) {
      return l10n.recouvrementRelanceListTooLarge(cap.lines, cap.cap);
    }

    // ⚠️ **L'intercepteur global rend des `Failure` NUES sur 403 et 404** —
    // `UnauthorizedFailure` et `NotFoundFailure`, sans le mixin `ApiErrorDetails`.
    // Les chercher par `code` ne les trouvait jamais, et les deux tombaient sur
    // le message générique : un serveur qui n'a pas encore la route faisait
    // chercher un bug dans l'app.
    if (failure is NotFoundFailure) {
      return l10n.recouvrementRelanceListNotDeployed;
    }
    if (failure is UnauthorizedFailure) {
      return l10n.recouvrementRelanceListForbidden;
    }

    if (failure is ApiErrorDetails) {
      final details = failure;
      switch (details.detailCode) {
        case 'UNKNOWN_STUDENTS':
          final count = _asInt(details.details?['count']);
          if (count != null) {
            return l10n.recouvrementRelanceListUnknownStudents(count);
          }
        case 'INCONSISTENT_LINE':
          // Notre bug, pas celui de l'utilisateur : on ne lui montre pas
          // l'index de la ligne fautive, qui ne lui apprendrait rien.
          return l10n.recouvrementRelanceListInconsistent;
      }
      final server = details.serverMessage;
      if (server != null && server.isNotEmpty) return server;
    }

    return l10n.recouvrementRelanceListFailed;
  }

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v.trim()),
    _ => null,
  };
}
