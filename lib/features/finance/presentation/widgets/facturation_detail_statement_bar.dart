import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_ledger_freshness_caption.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne sous la bande de KPI : fraîcheur du grand-livre à gauche, émission du
/// relevé de compte à droite.
///
/// Le relevé vit ici plutôt que dans un module à part parce que son contexte
/// naturel est celui de l'écran : le solde qu'il atteste est précisément celui
/// affiché au-dessus, et l'élève comme l'année sont déjà résolus.
class FacturationDetailStatementBar extends StatelessWidget {
  final String studentId;
  final String academicYearId;

  const FacturationDetailStatementBar({
    super.key,
    required this.studentId,
    required this.academicYearId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final caption = FacturationLedgerFreshnessCaption(studentId: studentId);
        final action = _StatementAction(
          studentId: studentId,
          academicYearId: academicYearId,
        );

        if (constraints.maxWidth < AppBreakpoints.formMediumMin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              caption,
              const SizedBox(height: AppDimensions.spacingS),
              action,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: caption),
            const SizedBox(width: AppDimensions.spacingM),
            action,
          ],
        );
      },
    );
  }
}

class _StatementAction extends StatelessWidget {
  final String studentId;
  final String academicYearId;

  const _StatementAction({
    required this.studentId,
    required this.academicYearId,
  });

  /// Le serveur répond 404 quand l'élève n'a aucune créance sur l'année : rien
  /// à relever. On l'éteint plutôt que de laisser cliquer vers une erreur.
  bool _hasCharges(StudentChargesState state) =>
      state.status == StudentChargesStatus.success &&
      state.studentCharges.isNotEmpty;

  Future<void> _onPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    // Confirmation obligatoire : chaque émission consomme un numéro de séquence
    // côté serveur et la pièce n'est jamais archivée. Un double appui distrait
    // produirait deux relevés numérotés distincts pour le même élève, sans que
    // rien ne le signale.
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: l10n.facturationDetailStatementConfirmTitle,
      message: l10n.facturationDetailStatementConfirmMessage,
      confirmLabel: l10n.facturationDetailStatementConfirmAction,
      cancelLabel: l10n.facturationDetailStatementConfirmCancel,
      headerIcon: Icons.receipt_long_outlined,
      confirmIcon: Icons.description_outlined,
    );
    if (!confirmed || !context.mounted) return;

    await showEditiqueAccountStatementDialog(
      context,
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<StudentChargesBloc, StudentChargesState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.studentCharges.length != curr.studentCharges.length,
      builder: (context, state) {
        final enabled = _hasCharges(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Émettre une pièce numérotée avance une séquence comptable côté
            // serveur : c'est une écriture, elle est gelée en session
            // lecture seule au même titre qu'un encaissement.
            SessionWriteGate(
              child: EteeloButton.secondary(
                label: l10n.facturationDetailStatementLabel,
                icon: Icons.description_outlined,
                onPressed: enabled ? () => _onPressed(context) : null,
                // Hors colonne pleine largeur : sans cela le thème étirerait le
                // bouton sur toute la ligne.
                fullWidth: false,
              ),
            ),
            if (!enabled && state.status == StudentChargesStatus.success) ...[
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                l10n.facturationDetailStatementNoChargesHint,
                textAlign: TextAlign.end,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
