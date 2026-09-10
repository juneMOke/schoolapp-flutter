import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_report.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_report_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Télécharger le rapport des paiements de la fenêtre affichée.
///
/// ## La sortie de la table, et rien d'autre
///
/// Le document rend **exactement** ce que la carte montre : la même fenêtre,
/// les mêmes lignes, toutes caisses confondues. Aucune devise ne le cadre —
/// son pied porte un total par devise plutôt qu'une somme, ce qui est la seule
/// façon d'imprimer deux unités sans inviter à les additionner.
///
/// ⚠️ **Le choix de caisse a été retiré.** Le serveur exigeait `currency` : le
/// bouton ouvrait alors un menu, parce qu'en désigner une en silence aurait
/// rendu un document crédible sur une caisse que personne n'avait demandée.
/// Depuis que le rapport porte les deux unités, la question n'a plus d'objet —
/// et un menu à une seule issue possible est pire qu'un bouton.
///
/// ## La fenêtre est celle de la TABLE, pas celle du sélecteur
///
/// Elle est lue sur l'état des reçus, donc sur la fenêtre qui a réellement
/// produit les lignes à l'écran. Prendre celle du sélecteur daterait le
/// document d'une période encore en vol pendant un changement de filtre.
///
/// ## Ce qui se passe quand ça ne marche pas
///
/// Le **429** n'est pas une panne : le serveur ne compose qu'un rapport à la
/// fois, et la file est partagée avec les autres pièces de période. Le bouton
/// reste désarmé le temps annoncé et le dit ; réarmer tout de suite inviterait
/// à reproduire ce qui vient d'être refusé. Le **400** du plafond porte le
/// compte réel de lignes dans son message, affiché tel quel : « resserrez »
/// sans dire de combien ne servirait à rien.
///
/// ⚠️ **Le plafond de 5 000 lignes se heurte plus tôt qu'avant.** Le document
/// couvrant désormais les deux caisses, une même période y compte deux fois
/// plus de lignes qu'au temps où il en cadrait une. Rien à coder pour ça — le
/// serveur refuse et le dit — mais c'est la raison pour laquelle un refus peut
/// apparaître sur une fenêtre qui passait hier.
class FinanceTillReportButton extends StatelessWidget {
  /// La fenêtre qui a produit la table.
  final TillWindow window;

  const FinanceTillReportButton({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    // ⚠️ **Les deux permissions, comme le serveur.** Le pilotage seul reçoit
    // 200 sur les cartes et 403 ici : offrir le bouton à qui n'a pas le
    // nominatif promettrait un geste qui échoue.
    return PermissionGate(
      requires: const [Perm.financeStatsRead, Perm.financePaymentRead],
      // ⚠️ **Conjonction, et il faut la demander** : `requiresAll` vaut `false`
      // par défaut, si bien qu'une liste de deux permissions signifie « l'une
      // ou l'autre ». Le serveur, lui, exige les deux — sans ce drapeau, le
      // porteur du seul pilotage verrait le bouton et récolterait un 403.
      requiresAll: true,
      child: BlocConsumer<FinanceTillReportCubit, FinanceTillReportState>(
        listenWhen: (prev, curr) => curr.hasDelivery,
        listener: _deliver,
        builder: (context, state) => _Label(
          state: state,
          onPressed: () =>
              context.read<FinanceTillReportCubit>().download(window: window),
        ),
      ),
    );
  }

  /// Remet le document — ou dit pourquoi il n'y en a pas — puis vide l'état.
  ///
  /// `Printing.layoutPdf` et non `sharePdf` : le partage système **écrit la
  /// pièce en clair dans le cache de l'application et ne l'efface jamais**, et
  /// ce rapport porte des noms d'élèves et de caissiers. Le spouleur, lui,
  /// propose « enregistrer en PDF » sans laisser de copie derrière lui.
  static Future<void> _deliver(
    BuildContext context,
    FinanceTillReportState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<FinanceTillReportCubit>();
    final report = state.report;

    if (report != null) {
      await _handOver(context, report, l10n);
    } else if (state.failure case final failure?) {
      AppSnackBar.showError(context, _message(failure, state, l10n));
    }

    // L'état se vide dans tous les cas : un document laissé là serait re-remis
    // à la reconstruction suivante, un message rejoué à chaque retour d'onglet.
    if (!cubit.isClosed) cubit.acknowledge();
  }

  static Future<void> _handOver(
    BuildContext context,
    TillReport report,
    AppLocalizations l10n,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => report.bytes,
        // Le nom vient du serveur et n'est jamais réécrit : il porte les bornes
        // réellement retenues.
        name: report.fileName,
      );
    } catch (_) {
      // Le canal natif peut manquer — binaire antérieur à la dépendance, ou
      // plateforme sans service d'impression. Le document est arrivé ; c'est le
      // geste qui a échoué, et le taire ne laisserait rien à l'écran.
      if (!context.mounted) return;
      AppSnackBar.showError(context, l10n.financeTillReportHandoffFailed);
    }
  }

  /// Ce qu'on dit au lecteur, dans **sa** langue quand c'est possible.
  ///
  /// ⚠️ **L'ordre compte.** Le refus de plafond est d'abord reconnu à son
  /// `detailCode` et rendu avec **nos** mots et **ses** chiffres ; à défaut
  /// seulement on retombe sur la phrase du serveur, qui porte l'information
  /// mais pas la langue de l'écran.
  ///
  /// Se brancher sur le code et non sur la phrase est la règle du socle : la
  /// phrase se reformule, le code est une valeur de fil.
  static String _message(
    Failure failure,
    FinanceTillReportState state,
    AppLocalizations l10n,
  ) {
    if (failure is TooManyRequestsFailure) {
      return l10n.financeTillReportBusy(state.retryAfter?.inSeconds ?? 60);
    }
    if (failure is UnauthorizedFailure) return l10n.financeTillReportForbidden;

    final capped = _lineCapMessage(failure, l10n);
    if (capped != null) return capped;

    final server = failure.message;
    return server.trim().isEmpty ? l10n.financeTillReportFailed : server;
  }

  /// « Cette fenêtre contient 7 213 lignes ; le rapport est plafonné à 5 000. »
  ///
  /// ⚠️ **Les deux chiffres viennent de `details`, jamais de la phrase.** Les
  /// extraire du texte par expression régulière casserait à la première
  /// reformulation du serveur — et c'est précisément pour éviter ça qu'il les
  /// rend séparément.
  ///
  /// Rend `null` dès qu'un des deux manque ou n'est pas un nombre : mieux vaut
  /// la phrase du serveur, complète mais dans sa langue, qu'une phrase à trous
  /// dans la nôtre.
  ///
  /// **Ce refus n'appartient pas qu'à la caisse** — le registre des inscriptions
  /// et la liste de relance lèvent le même `REPORT_LINE_CAP`. La lecture des
  /// chiffres est donc montée au socle ([ReportLineCap]) ; il ne reste ici que
  /// les mots de cet écran.
  static String? _lineCapMessage(Failure failure, AppLocalizations l10n) {
    final cap = ReportLineCap.of(failure);
    return cap == null
        ? null
        : l10n.financeTillReportTooLarge(cap.lines, cap.cap);
  }
}

/// L'étiquette du bouton, qui **dit dans quel état il est**.
class _Label extends StatelessWidget {
  final FinanceTillReportState state;
  final VoidCallback onPressed;

  const _Label({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = state.isBusy;

    final (String label, Widget leading) = switch (state.status) {
      FinanceTillReportStatus.preparing => (
        l10n.financeTillReportPreparing,
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      FinanceTillReportStatus.cooldown => (
        l10n.financeTillReportWaiting,
        const Icon(Icons.hourglass_top_rounded, size: 16),
      ),
      FinanceTillReportStatus.idle => (
        l10n.financeTillReportDownload,
        const Icon(Icons.download_outlined, size: 16),
      ),
    };

    return Tooltip(
      message: busy ? label : l10n.financeTillReportTooltip,
      child: TextButton.icon(
        // Désarmé pendant le rendu ET pendant l'attente d'un 429 : le serveur
        // ne compose qu'un rapport à la fois.
        onPressed: busy ? null : onPressed,
        icon: leading,
        label: Text(label, style: AppTextStyles.action),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.bleuArdoise,
          // Sans plancher, un bouton inline hérite du thème pleine largeur du
          // socle et fait déborder la ligne de titre.
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
