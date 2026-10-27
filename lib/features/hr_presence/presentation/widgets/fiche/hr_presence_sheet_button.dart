import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_attendance_report_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Télécharger la fiche de présence de l'agent, sur la portée affichée : le
/// mois (pièce FP scellée si le mois est clos, provisoire sinon — le serveur
/// choisit) ou l'année (provisoire en V1).
///
/// Un mois clos exige aussi `editique.write` : sans lui, le bouton se cache
/// plutôt que de laisser venir un 403. Des pointages de l'agent pas encore
/// envoyés : on prévient avant le tirage, le serveur ne les voit pas.
class HrPresenceSheetButton extends StatelessWidget {
  final HrPresenceFicheState state;

  const HrPresenceSheetButton({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = state.local;
    final sealed = !state.yearly && (local?.monthClosed ?? false);
    if (sealed && !PermissionGate.allows(context, const [Perm.editiqueWrite])) {
      return const SizedBox.shrink();
    }
    final ready =
        state.status == HrPresenceFicheStatus.ready &&
        (state.yearly ? state.yearData : state.monthData) != null;
    return HrAttendanceReportButton(
      kind: HrAttendanceReportKind.sheet,
      tooltip: sealed
          ? l10n.hrPresenceSheetTooltipSealed
          : l10n.hrPresenceSheetTooltipDraft,
      onDownload: !ready
          ? null
          : (report) async {
              final unsent = local?.unsent ?? 0;
              if (unsent > 0) {
                final go = await showAppConfirmationDialog(
                  context: context,
                  title: l10n.hrPresenceSheetUnsentTitle,
                  message: l10n.hrPresenceSheetUnsentMessage(unsent),
                  confirmLabel: l10n.hrPresenceSheetUnsentConfirm,
                  cancelLabel: MaterialLocalizations.of(
                    context,
                  ).cancelButtonLabel,
                  headerIcon: Icons.cloud_upload_outlined,
                );
                if (!go || report.isClosed) return;
              }
              await report.downloadSheet(
                state.agentId,
                month: state.yearly ? null : state.month,
              );
            },
    );
  }
}
