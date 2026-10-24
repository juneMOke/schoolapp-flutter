import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_list_report_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Télécharger la liste affichée — pièce LP, composée par le serveur sur **la
/// question qui a produit la liste** : même recherche, même catégorie, même
/// ordre, toutes pages.
///
/// Le geste de la boutique : le bouton dit qu'il prépare, reste désarmé le
/// temps d'un 429, et le document s'ouvre dans la visionneuse partagée.
class HrStaffListReportButton extends StatelessWidget {
  /// `null` : rien à imprimer (liste vide, pas encore lue, en échec).
  final HrRosterQuery? query;

  const HrStaffListReportButton({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HrStaffListReportCubit, HrStaffListReportState>(
      listenWhen: (prev, curr) => curr.hasDelivery,
      listener: _deliver,
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final label = switch (state.status) {
          HrStaffListReportStatus.preparing => l10n.hrStaffReportPreparing,
          HrStaffListReportStatus.cooldown => l10n.hrStaffReportWaiting,
          HrStaffListReportStatus.idle => l10n.hrRosterPdf,
        };
        final asked = query;
        return EteeloButton.secondary(
          label: label,
          icon: state.status == HrStaffListReportStatus.cooldown
              ? Icons.hourglass_top_rounded
              : Icons.picture_as_pdf_outlined,
          tooltip: state.isBusy ? label : l10n.hrRosterPdfTooltip,
          isLoading: state.status == HrStaffListReportStatus.preparing,
          // Désarmé pendant le rendu ET pendant l'attente d'un 429.
          onPressed: state.isBusy || asked == null
              ? null
              : () => context.read<HrStaffListReportCubit>().download(asked),
          fullWidth: false,
        );
      },
    );
  }

  static Future<void> _deliver(
    BuildContext context,
    HrStaffListReportState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrStaffListReportCubit>();
    final report = state.report;

    if (report != null) {
      await showEteeloDocumentViewer(
        context,
        title: l10n.hrStaffReportTitle,
        // Le nom vient du serveur et n'est jamais réécrit.
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
    HrStaffListReportState state,
    AppLocalizations l10n,
  ) {
    if (failure is TooManyRequestsFailure) {
      final wait =
          state.retryAfter ?? AppConstants.hrStaffListReportRetryFallback;
      return l10n.hrStaffReportBusy(wait.inSeconds);
    }
    if (failure is UnauthorizedFailure) return l10n.hrStaffReportForbidden;
    if (failure is InvalidCredentialsFailure || failure is AuthFailure) {
      return l10n.hrStaffReportSessionExpired;
    }
    // La seule 404 de la route : l'école n'a pas d'année en cours, dont la
    // pièce tire son numéro.
    if (failure is NotFoundFailure) return l10n.hrStaffReportNoYear;
    final cap = ReportLineCap.of(failure);
    if (cap != null) return l10n.hrStaffReportTooLarge(cap.lines, cap.cap);

    final sentence = switch (failure) {
      ApiErrorDetails(:final serverMessage?) => serverMessage.trim(),
      _ => null,
    };
    return sentence == null || sentence.isEmpty
        ? l10n.hrStaffReportFailed
        : sentence;
  }
}
