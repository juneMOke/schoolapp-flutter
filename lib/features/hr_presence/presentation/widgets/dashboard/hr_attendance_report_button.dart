import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/error/report_line_cap.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_attendance_report_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Quelle pièce le bouton tire : ses mots (titre de la visionneuse, échecs).
enum HrAttendanceReportKind {
  /// L'assiduité du tableau de bord (pièce AP).
  attendance,

  /// La liste de la fiche individuelle (pièce PR).
  profiles,

  /// La fiche de présence d'un agent (FP scellée, ou provisoire).
  sheet,
}

/// Télécharger un PDF de présence composé par le serveur sur **la même
/// question que l'écran** (règle 14) : la demande vient de l'appelant
/// ([onDownload]), la préparation, l'attente d'un 429 et la remise sont
/// communes.
class HrAttendanceReportButton extends StatelessWidget {
  /// `null` : rien à imprimer (liste vide, pas encore lue, en échec).
  final Future<void> Function(HrAttendanceReportCubit cubit)? onDownload;
  final HrAttendanceReportKind kind;

  /// L'infobulle au repos ; `null` : celle de la pièce.
  final String? tooltip;

  const HrAttendanceReportButton({
    super.key,
    required this.onDownload,
    this.kind = HrAttendanceReportKind.attendance,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HrAttendanceReportCubit, HrAttendanceReportState>(
      listenWhen: (prev, curr) => curr.hasDelivery,
      listener: (context, state) => _deliver(context, state, kind),
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final label = switch (state.status) {
          HrAttendanceReportStatus.preparing => l10n.hrStaffReportPreparing,
          HrAttendanceReportStatus.cooldown => l10n.hrStaffReportWaiting,
          HrAttendanceReportStatus.idle => l10n.hrRosterPdf,
        };
        final download = onDownload;
        return EteeloButton.secondary(
          label: label,
          icon: state.status == HrAttendanceReportStatus.cooldown
              ? Icons.hourglass_top_rounded
              : Icons.picture_as_pdf_outlined,
          tooltip: state.isBusy ? label : tooltip ?? _tooltip(l10n),
          isLoading: state.status == HrAttendanceReportStatus.preparing,
          onPressed: state.isBusy || download == null
              ? null
              : () => download(context.read<HrAttendanceReportCubit>()),
          fullWidth: false,
        );
      },
    );
  }

  String _tooltip(AppLocalizations l10n) => switch (kind) {
    HrAttendanceReportKind.attendance => l10n.hrPresenceReportTooltip,
    HrAttendanceReportKind.profiles => l10n.hrPresenceProfilesReportTooltip,
    HrAttendanceReportKind.sheet => l10n.hrPresenceSheetTooltip,
  };

  static Future<void> _deliver(
    BuildContext context,
    HrAttendanceReportState state,
    HrAttendanceReportKind kind,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrAttendanceReportCubit>();
    final report = state.report;

    if (report != null) {
      await showEteeloDocumentViewer(
        context,
        title: switch (kind) {
          HrAttendanceReportKind.attendance => l10n.hrPresenceReportTitle,
          HrAttendanceReportKind.profiles => l10n.hrPresenceProfilesReportTitle,
          HrAttendanceReportKind.sheet => l10n.hrPresenceSheetTitle,
        },
        // Le nom vient du serveur et n'est jamais réécrit.
        document: PrintableDocument(
          bytes: report.bytes,
          fileName: report.fileName,
        ),
      );
    } else if (state.failure case final failure?) {
      AppSnackBar.showError(context, message(failure, state, l10n, kind: kind));
    }

    if (!cubit.isClosed) cubit.acknowledge();
  }

  /// Nos mots et les chiffres du serveur quand on les reconnaît ; sa phrase à
  /// défaut.
  @visibleForTesting
  static String message(
    Failure failure,
    HrAttendanceReportState state,
    AppLocalizations l10n, {
    HrAttendanceReportKind kind = HrAttendanceReportKind.attendance,
  }) {
    final sheet = kind == HrAttendanceReportKind.sheet;
    if (failure is TooManyRequestsFailure) {
      final wait =
          state.retryAfter ?? AppConstants.hrAttendanceReportRetryFallback;
      return l10n.hrStaffReportBusy(wait.inSeconds);
    }
    // La fiche d'un mois clos est scellée : elle exige aussi l'émission.
    if (failure is UnauthorizedFailure) {
      return sheet
          ? l10n.hrPresenceSheetForbidden
          : l10n.hrPresenceReportForbidden;
    }
    if (failure is InvalidCredentialsFailure || failure is AuthFailure) {
      return l10n.hrStaffReportSessionExpired;
    }
    // La pièce tire son numéro de l'année en cours ; la fiche, aussi son agent.
    if (failure is NotFoundFailure) {
      return sheet ? l10n.hrPresenceSheetNotFound : l10n.hrPresenceReportNoYear;
    }
    final cap = ReportLineCap.of(failure);
    if (cap != null) {
      return l10n.hrPresenceReportTooLarge(cap.lines, cap.cap);
    }
    final sentence = switch (failure) {
      ApiErrorDetails(:final serverMessage?) => serverMessage.trim(),
      _ => null,
    };
    if (sentence != null && sentence.isNotEmpty) return sentence;
    return switch (kind) {
      HrAttendanceReportKind.attendance => l10n.hrPresenceReportFailed,
      HrAttendanceReportKind.profiles => l10n.hrPresenceProfilesReportFailed,
      HrAttendanceReportKind.sheet => l10n.hrPresenceSheetFailed,
    };
  }
}
