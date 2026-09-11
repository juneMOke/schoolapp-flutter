import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_report_cubit.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_export_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Télécharger le **registre des inscrits** de la fenêtre affichée.
///
/// ## Le serveur compose, l'écran remet
///
/// Le document n'est plus composé sur l'appareil à partir de la page visible :
/// il vient de `/entries.pdf`, qui lit la même fenêtre et dans le même ordre
/// que la table, mais **toutes les lignes** — pas les huit à l'écran. En-tête
/// d'établissement, pagination `n / N`, numéro de pièce et scellement : c'est
/// le registre qu'une direction signe et classe. Même chemin que le rapport de
/// la caisse, sur le tableau de bord Finances.
///
/// ## La fenêtre est celle de la LISTE, pas celle du sélecteur
///
/// Elle est lue sur l'état de la liste, donc sur la fenêtre dont les lignes
/// sont à l'écran. Prendre celle du sélecteur daterait le document d'une
/// période encore en vol pendant un changement de filtre.
///
/// ## Ce qui se passe quand ça ne marche pas
///
/// Le **429** n'est pas une panne : le serveur ne compose qu'un document long
/// à la fois, file partagée avec la caisse et la relance. Le bouton reste
/// désarmé le temps annoncé et le dit. Le **400** du plafond (5 000 lignes)
/// dit le compte réel et demande de resserrer la période — sans promettre
/// d'export : cette liste n'en a pas.
class EnrollmentEntriesReportButton extends StatelessWidget {
  /// La fenêtre dont les lignes sont à l'écran.
  final EnrollmentStatsWindow window;

  const EnrollmentEntriesReportButton({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    // ⚠️ **Les deux permissions, comme le serveur — et en conjonction.**
    // `requiresAll` vaut `false` par défaut : sans lui, le porteur du seul
    // pilotage verrait le bouton et récolterait un 403.
    return PermissionGate(
      requires: const [Perm.enrollmentStatsRead, Perm.enrollmentRead],
      requiresAll: true,
      child:
          BlocConsumer<
            EnrollmentEntriesReportCubit,
            EnrollmentEntriesReportState
          >(
            listenWhen: (prev, curr) => curr.hasDelivery,
            listener: _deliver,
            builder: (context, state) {
              final l10n = AppLocalizations.of(context)!;
              final label = switch (state.status) {
                EnrollmentEntriesReportStatus.preparing =>
                  l10n.enrollmentDashboardEntriesReportPreparing,
                EnrollmentEntriesReportStatus.cooldown =>
                  l10n.enrollmentDashboardEntriesReportWaiting,
                EnrollmentEntriesReportStatus.idle =>
                  l10n.enrollmentDashboardExportPdf,
              };

              return EnrollmentExportButton(
                icon: state.status == EnrollmentEntriesReportStatus.cooldown
                    ? Icons.hourglass_top_rounded
                    : Icons.download_outlined,
                busy: state.status == EnrollmentEntriesReportStatus.preparing,
                label: label,
                tooltip: state.isBusy
                    ? label
                    : l10n.enrollmentDashboardEntriesReportTooltip,
                // Désarmé pendant le rendu ET pendant l'attente d'un 429.
                onPressed: state.isBusy
                    ? null
                    : () => context
                          .read<EnrollmentEntriesReportCubit>()
                          .download(window: window),
              );
            },
          ),
    );
  }

  /// Remet le document — ou dit pourquoi il n'y en a pas — puis vide l'état.
  static Future<void> _deliver(
    BuildContext context,
    EnrollmentEntriesReportState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EnrollmentEntriesReportCubit>();
    final report = state.report;

    if (report != null) {
      await _handOver(context, report, l10n);
    } else if (state.failure case final failure?) {
      AppSnackBar.showError(context, message(failure, state, l10n));
    }

    // L'état se vide dans tous les cas : un document laissé là serait re-remis
    // à la reconstruction suivante, un message rejoué à chaque retour.
    if (!cubit.isClosed) cubit.acknowledge();
  }

  /// `Printing.layoutPdf` et non `sharePdf` : le partage système **écrit la
  /// pièce en clair dans le cache de l'application et ne l'efface jamais**, et
  /// ce registre porte des noms d'élèves. Le spouleur, lui, propose
  /// « enregistrer en PDF » sans laisser de copie derrière lui.
  static Future<void> _handOver(
    BuildContext context,
    EnrollmentEntriesReport report,
    AppLocalizations l10n,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => report.bytes,
        // Le nom vient du serveur et n'est jamais réécrit : il porte le
        // périmètre réellement retenu.
        name: report.fileName,
      );
    } catch (_) {
      // Le canal natif peut manquer — plateforme sans service d'impression.
      // Le document est arrivé ; c'est le geste qui a échoué, et le taire ne
      // laisserait rien à l'écran.
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        l10n.enrollmentDashboardEntriesReportHandoffFailed,
      );
    }
  }

  /// Ce qu'on dit au lecteur, dans **sa** langue quand c'est possible.
  ///
  /// ⚠️ **L'ordre compte.** Le refus de plafond est d'abord reconnu à son
  /// `detailCode` et rendu avec **nos** mots et **ses** chiffres ; à défaut
  /// seulement on retombe sur la phrase du serveur, qui porte l'information
  /// mais pas la langue de l'écran.
  @visibleForTesting
  static String message(
    Failure failure,
    EnrollmentEntriesReportState state,
    AppLocalizations l10n,
  ) {
    if (failure is TooManyRequestsFailure) {
      final wait =
          state.retryAfter ?? AppConstants.enrollmentEntriesReportRetryFallback;
      return l10n.enrollmentDashboardEntriesReportBusy(wait.inSeconds);
    }
    if (failure is UnauthorizedFailure) {
      return l10n.enrollmentDashboardEntriesReportForbidden;
    }

    final cap = ReportLineCap.of(failure);
    if (cap != null) {
      return l10n.enrollmentDashboardEntriesReportTooLarge(cap.lines, cap.cap);
    }

    return _serverSentence(failure) ??
        l10n.enrollmentDashboardEntriesReportFailed;
  }

  /// La phrase du serveur, quand il en a dit une.
  ///
  /// ⚠️ **Sur cette route binaire, le plafond arrive souvent sans son code.**
  /// `EditiqueFailureMapper` va chercher le message dans un corps parti en
  /// octets, mais rebâtit alors une `ValidationFailure` **nue** : le
  /// `detailCode` et ses chiffres ne survivent pas. La phrase, elle, porte le
  /// compte réel — d'où ce second filet. Le message par défaut de
  /// `ValidationFailure` n'en est pas un : c'est une constante anglaise, qui
  /// cède la place à notre message générique.
  static String? _serverSentence(Failure failure) {
    final sentence = switch (failure) {
      ApiErrorDetails(:final serverMessage?) => serverMessage,
      ValidationFailure(:final message)
          when message != const ValidationFailure().message =>
        message,
      _ => null,
    };
    final trimmed = sentence?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
