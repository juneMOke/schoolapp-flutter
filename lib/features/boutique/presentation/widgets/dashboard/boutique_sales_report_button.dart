import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_report_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Télécharger le rapport des ventes affichées — pièce VB, composée par le
/// serveur sur **la question qui a produit la liste** : même fenêtre, même
/// filtre, toutes pages.
///
/// Le geste de la caisse et du registre des inscriptions : le bouton dit qu'il
/// prépare, reste désarmé le temps d'un 429, et le document s'ouvre dans la
/// visionneuse partagée (voir, imprimer, partager).
class BoutiqueSalesReportButton extends StatelessWidget {
  final SalesQuery query;

  const BoutiqueSalesReportButton({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BoutiqueSalesReportCubit, BoutiqueSalesReportState>(
      listenWhen: (prev, curr) => curr.hasDelivery,
      listener: _deliver,
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final label = switch (state.status) {
          BoutiqueSalesReportStatus.preparing =>
            l10n.boutiqueSalesReportPreparing,
          BoutiqueSalesReportStatus.cooldown => l10n.boutiqueSalesReportWaiting,
          BoutiqueSalesReportStatus.idle => l10n.boutiqueSalesReportDownload,
        };
        return Tooltip(
          message: state.isBusy ? label : l10n.boutiqueSalesReportTooltip,
          child: EteeloButton.ghost(
            label: label,
            icon: state.status == BoutiqueSalesReportStatus.cooldown
                ? Icons.hourglass_top_rounded
                : Icons.download_outlined,
            isLoading: state.status == BoutiqueSalesReportStatus.preparing,
            // Désarmé pendant le rendu ET pendant l'attente d'un 429.
            onPressed: state.isBusy
                ? null
                : () =>
                      context.read<BoutiqueSalesReportCubit>().download(query),
            fullWidth: false,
          ),
        );
      },
    );
  }

  static Future<void> _deliver(
    BuildContext context,
    BoutiqueSalesReportState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BoutiqueSalesReportCubit>();
    final report = state.report;

    if (report != null) {
      await showEteeloDocumentViewer(
        context,
        title: l10n.boutiqueSalesReportTitle,
        // Le nom vient du serveur et n'est jamais réécrit : il porte les
        // bornes réellement retenues.
        document: PrintableDocument(
          bytes: report.bytes,
          fileName: report.fileName,
        ),
      );
    } else if (state.failure case final failure?) {
      AppSnackBar.showError(context, message(failure, state, l10n));
    }

    // Dans tous les cas : un document laissé là serait re-remis à la
    // reconstruction suivante, un message rejoué à chaque retour.
    if (!cubit.isClosed) cubit.acknowledge();
  }

  /// Nos mots et les chiffres du serveur quand on les reconnaît ; sa phrase à
  /// défaut, plutôt qu'une phrase à trous.
  @visibleForTesting
  static String message(
    Failure failure,
    BoutiqueSalesReportState state,
    AppLocalizations l10n,
  ) {
    if (failure is TooManyRequestsFailure) {
      final wait =
          state.retryAfter ?? AppConstants.boutiqueSalesReportRetryFallback;
      return l10n.boutiqueSalesReportBusy(wait.inSeconds);
    }
    if (failure is UnauthorizedFailure) {
      return l10n.boutiqueSalesReportForbidden;
    }
    final cap = ReportLineCap.of(failure);
    if (cap != null) {
      return l10n.boutiqueSalesReportTooLarge(cap.lines, cap.cap);
    }

    final sentence = switch (failure) {
      ApiErrorDetails(:final serverMessage?) => serverMessage.trim(),
      _ => null,
    };
    return sentence == null || sentence.isEmpty
        ? l10n.boutiqueSalesReportFailed
        : sentence;
  }
}
