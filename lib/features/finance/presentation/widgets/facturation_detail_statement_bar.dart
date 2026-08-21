import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
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

    // Trois gardes indépendantes, dans l'ordre où elles s'expliquent à
    // l'utilisateur. Chacune a un motif distinct et un message distinct :
    //  1. l'élève n'est pas encore connu du serveur → l'appel donnerait un 404 ;
    //  2. la radio est coupée → le relevé est une émission serveur, point ;
    //  3. l'élève n'a aucune créance → le serveur répond 404 « rien à relever ».
    // La quatrième (session en lecture seule) reste portée par SessionWriteGate.
    final isOffline =
        context.watch<SyncStatusCubit>().state.status == SyncStatus.offline;

    return BlocBuilder<EditiqueEligibilityCubit, EditiqueEligibilityState>(
      builder: (context, eligibility) {
        return BlocBuilder<StudentChargesBloc, StudentChargesState>(
          buildWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.studentCharges.length != curr.studentCharges.length,
          builder: (context, state) {
            final hasCharges = _hasCharges(state);
            final enabled = eligibility.isEligible && !isOffline && hasCharges;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Émettre une pièce numérotée avance une séquence comptable côté
                // serveur : c'est une écriture, elle est gelée en session
                // lecture seule au même titre qu'un encaissement.
                PermissionGate(
                  requires: const [Perm.editiqueWrite],
                  child: SessionWriteGate(
                    child: EteeloButton.secondary(
                      label: l10n.facturationDetailStatementLabel,
                      icon: Icons.description_outlined,
                      onPressed: enabled ? () => _onPressed(context) : null,
                      // Hors colonne pleine largeur : sans cela le thème
                      // étirerait le bouton sur toute la ligne.
                      fullWidth: false,
                    ),
                  ),
                ),
                if (_hint(l10n, eligibility, isOffline, state)
                    case final hint?) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    hint,
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
      },
    );
  }

  /// Message d'accompagnement du bouton éteint, `null` quand il est actif ou
  /// quand la cause n'est pas encore établie (résolution en cours, créances non
  /// chargées) — on n'annonce jamais une raison qu'on ne connaît pas.
  String? _hint(
    AppLocalizations l10n,
    EditiqueEligibilityState eligibility,
    bool isOffline,
    StudentChargesState state,
  ) {
    if (eligibility.isBlocked) {
      return l10n.facturationDetailStatementPendingSyncHint;
    }
    if (isOffline) return l10n.facturationDetailStatementOfflineHint;
    if (!_hasCharges(state) && state.status == StudentChargesStatus.success) {
      return l10n.facturationDetailStatementNoChargesHint;
    }
    return null;
  }
}
