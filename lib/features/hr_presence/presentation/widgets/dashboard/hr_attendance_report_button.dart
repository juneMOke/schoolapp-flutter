import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_attendance_report_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Télécharger l'assiduité affichée — pièce AP, composée par le serveur sur
/// **la même question que la liste** : même fenêtre, même recherche, même
/// ordre (règle 14). Le geste de la liste du personnel.
class HrAttendanceReportButton extends StatelessWidget {
  /// `null` : rien à imprimer (liste vide, pas encore lue, en échec).
  final DashboardWindow? window;
  final String search;

  const HrAttendanceReportButton({
    super.key,
    required this.window,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HrAttendanceReportCubit, HrAttendanceReportState>(
      listenWhen: (prev, curr) => curr.hasDelivery,
      listener: _deliver,
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final label = switch (state.status) {
          HrAttendanceReportStatus.preparing => l10n.hrStaffReportPreparing,
          HrAttendanceReportStatus.cooldown => l10n.hrStaffReportWaiting,
          HrAttendanceReportStatus.idle => l10n.hrRosterPdf,
        };
        final asked = window;
        return EteeloButton.secondary(
          label: label,
          icon: state.status == HrAttendanceReportStatus.cooldown
              ? Icons.hourglass_top_rounded
              : Icons.picture_as_pdf_outlined,
          tooltip: state.isBusy ? label : l10n.hrPresenceReportTooltip,
          isLoading: state.status == HrAttendanceReportStatus.preparing,
          onPressed: state.isBusy || asked == null
              ? null
              : () => context.read<HrAttendanceReportCubit>().download(
                  asked,
                  search: search,
                ),
          fullWidth: false,
        );
      },
    );
  }

  static Future<void> _deliver(
    BuildContext context,
    HrAttendanceReportState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrAttendanceReportCubit>();
    final report = state.report;

    if (report != null) {
      await showEteeloDocumentViewer(
        context,
        title: l10n.hrPresenceReportTitle,
        // Le nom vient du serveur et n'est jamais réécrit.
        document: PrintableDocument(
          bytes: report.bytes,
          fileName: report.fileName,
        ),
      );
    } else if (state.failure case final failure?) {
      AppSnackBar.showError(context, message(failure, state, l10n));
    }

    if (!cubit.isClosed) cubit.acknowledge();
  }

  /// Nos mots et les chiffres du serveur quand on les reconnaît ; sa phrase à
  /// défaut.
  @visibleForTesting
  static String message(
    Failure failure,
    HrAttendanceReportState state,
    AppLocalizations l10n,
  ) {
    if (failure is TooManyRequestsFailure) {
      final wait =
          state.retryAfter ?? AppConstants.hrAttendanceReportRetryFallback;
      return l10n.hrStaffReportBusy(wait.inSeconds);
    }
    if (failure is UnauthorizedFailure) return l10n.hrPresenceReportForbidden;
    if (failure is InvalidCredentialsFailure || failure is AuthFailure) {
      return l10n.hrStaffReportSessionExpired;
    }
    // La pièce tire son numéro de l'année en cours.
    if (failure is NotFoundFailure) return l10n.hrPresenceReportNoYear;
    final cap = ReportLineCap.of(failure);
    if (cap != null) {
      return l10n.hrPresenceReportTooLarge(cap.lines, cap.cap);
    }
    final sentence = switch (failure) {
      ApiErrorDetails(:final serverMessage?) => serverMessage.trim(),
      _ => null,
    };
    return sentence == null || sentence.isEmpty
        ? l10n.hrPresenceReportFailed
        : sentence;
  }
}
