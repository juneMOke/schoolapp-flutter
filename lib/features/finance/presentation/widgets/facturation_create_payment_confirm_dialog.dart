import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_modal_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_collect_flow_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Issue de la sur-couche d'encaissement (confirmation → résultat).
enum FacturationCollectOutcome { edited, cancelled, succeeded }

/// Ligne de répartition affichée dans la confirmation : libellé + montant.
class FacturationConfirmAllocationItem {
  final String label;
  final String amount;

  const FacturationConfirmAllocationItem({
    required this.label,
    required this.amount,
  });
}

/// Sur-couche d'encaissement en 2 étapes (spec MODALE 12/17) — Confirmation
/// puis Résultat (processing → succès | échec). Le paiement n'est ajouté
/// qu'au succès ; aucun débit silencieux en cas d'échec.
///
/// Retourne [FacturationCollectOutcome.succeeded] si le paiement a été
/// enregistré, [edited] si l'utilisateur revient à la saisie, [cancelled]
/// sinon.
Future<FacturationCollectOutcome> showFacturationCreatePaymentConfirmDialog(
  BuildContext context, {
  required PaymentsBloc paymentsBloc,
  required String totalLabel,
  required String studentName,
  required String payerName,
  required List<FacturationConfirmAllocationItem> allocations,
  required PaymentsCreateRequested request,
  VoidCallback? onDownloadReceipt,
}) async {
  final outcome = await showDialog<FacturationCollectOutcome>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<PaymentsBloc>.value(
      value: paymentsBloc,
      child: _CollectFlowDialog(
        totalLabel: totalLabel,
        studentName: studentName,
        payerName: payerName,
        allocations: allocations,
        request: request,
        onDownloadReceipt: onDownloadReceipt,
      ),
    ),
  );
  return outcome ?? FacturationCollectOutcome.cancelled;
}

enum _Phase { confirm, processing, success, error }

class _CollectFlowDialog extends StatefulWidget {
  final String totalLabel;
  final String studentName;
  final String payerName;
  final List<FacturationConfirmAllocationItem> allocations;
  final PaymentsCreateRequested request;
  final VoidCallback? onDownloadReceipt;

  const _CollectFlowDialog({
    required this.totalLabel,
    required this.studentName,
    required this.payerName,
    required this.allocations,
    required this.request,
    this.onDownloadReceipt,
  });

  @override
  State<_CollectFlowDialog> createState() => _CollectFlowDialogState();
}

class _CollectFlowDialogState extends State<_CollectFlowDialog> {
  _Phase _phase = _Phase.confirm;
  bool _awaitingBloc = false;
  String? _incidentCode;

  void _confirm() {
    // Invariant « un seul traitement en vol » : ignore toute ré-entrance.
    if (_phase == _Phase.processing || _awaitingBloc) {
      return;
    }
    setState(() {
      _phase = _Phase.processing;
      _awaitingBloc = true;
    });
    context.read<PaymentsBloc>().add(widget.request);
  }

  void _onBlocState(PaymentsState state) {
    if (!mounted || !_awaitingBloc) return;
    if (state.createStatus == PaymentsStatus.success) {
      _awaitingBloc = false;
      // Le rafraîchissement du détail est déclenché APRÈS fermeture de la popin
      // (cf. _onCollect) pour qu'un éventuel échec de refresh ne contredise pas
      // l'écran de succès. La liste est déjà à jour (le bloc insère le paiement).
      setState(() => _phase = _Phase.success);
    } else if (state.createStatus == PaymentsStatus.failure) {
      _awaitingBloc = false;
      setState(() {
        _phase = _Phase.error;
        _incidentCode = _generateIncidentCode();
      });
    }
  }

  String _generateIncidentCode() =>
      'INC-${DateTime.now().millisecondsSinceEpoch.remainder(1000000)}';

  void _onDownloadReceipt() {
    if (widget.onDownloadReceipt != null) {
      widget.onDownloadReceipt!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.pageUnderConstruction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final resultActive = _phase != _Phase.confirm;

    return BlocListener<PaymentsBloc, PaymentsState>(
      listenWhen: (prev, curr) => prev.createStatus != curr.createStatus,
      listener: (_, state) => _onBlocState(state),
      // Pendant le traitement, la sortie est neutralisée (croix, scrim ET
      // bouton retour système) : une issue succès|échec est toujours rendue
      // avant fermeture → jamais de débit silencieux.
      child: PopScope(
        canPop: _phase != _Phase.processing && !_awaitingBloc,
        child: Dialog(
          backgroundColor: AppColors.surfaceRaised,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppDimensions.facturationCollectModalMaxWidth,
              maxHeight: maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // stretch : le corps occupe toute la largeur de la modale, donc
              // le contenu (médaillon/textes de l'étape résultat) est bien
              // centré et l'étape 1 n'est plus tassée à gauche.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CollectStepHeader(
                  resultActive: resultActive,
                  confirmLabel: l10n.facturationCollectStepConfirm,
                  resultLabel: l10n.facturationCollectStepResult,
                  onClose: _closeAction(),
                ),
                const FinanceModalGoldDivider(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    child: _phase == _Phase.confirm
                        ? _ConfirmBody(
                            totalLabel: widget.totalLabel,
                            studentName: widget.studentName,
                            payerName: widget.payerName,
                            allocations: widget.allocations,
                          )
                        : _ResultBody(
                            phase: _phase,
                            totalLabel: widget.totalLabel,
                            incidentCode: _incidentCode,
                          ),
                  ),
                ),
                _buildFooter(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Croix de fermeture selon la phase (aucune pendant le traitement).
  VoidCallback? _closeAction() => switch (_phase) {
    _Phase.confirm => () => Navigator.of(
      context,
    ).pop(FacturationCollectOutcome.edited),
    _Phase.success => () => Navigator.of(
      context,
    ).pop(FacturationCollectOutcome.succeeded),
    _Phase.error => () => Navigator.of(
      context,
    ).pop(FacturationCollectOutcome.cancelled),
    _Phase.processing => null,
  };

  Widget _buildFooter(AppLocalizations l10n) {
    switch (_phase) {
      case _Phase.processing:
        return const SizedBox.shrink();
      case _Phase.confirm:
        return Column(
          children: [
            const Divider(height: 1, color: AppColors.border),
            FinanceModalFooter(
              secondaryLabel: l10n.facturationCollectEditAction,
              secondaryIcon: Icons.edit_outlined,
              onSecondary: () =>
                  Navigator.of(context).pop(FacturationCollectOutcome.edited),
              primaryLabel: l10n.facturationCreatePaymentConfirmValidate,
              primaryIcon: Icons.check_circle_outline_rounded,
              onPrimary: _confirm,
              stackBelowWidth: AppBreakpoints.financeModalFooterRowMin,
            ),
          ],
        );
      case _Phase.success:
        return Column(
          children: [
            const Divider(height: 1, color: AppColors.border),
            FinanceModalFooter(
              secondaryLabel: l10n.facturationPaymentDownloadReceiptLabel,
              secondaryIcon: Icons.download_outlined,
              onSecondary: _onDownloadReceipt,
              primaryLabel: l10n.facturationPaymentCloseLabel,
              primaryIcon: Icons.check_rounded,
              onPrimary: () => Navigator.of(
                context,
              ).pop(FacturationCollectOutcome.succeeded),
              stackBelowWidth: AppBreakpoints.financeModalFooterRowMin,
            ),
          ],
        );
      case _Phase.error:
        return Column(
          children: [
            const Divider(height: 1, color: AppColors.border),
            FinanceModalFooter(
              secondaryLabel: l10n.facturationCreatePaymentConfirmCancel,
              secondaryIcon: Icons.close_rounded,
              onSecondary: () => Navigator.of(
                context,
              ).pop(FacturationCollectOutcome.cancelled),
              primaryLabel: l10n.facturationCollectRetryAction,
              primaryIcon: Icons.refresh_rounded,
              onPrimary: _confirm,
              stackBelowWidth: AppBreakpoints.financeModalFooterRowMin,
            ),
          ],
        );
    }
  }
}

/// Corps de l'étape 1 : récapitulatif + répartition.
class _ConfirmBody extends StatelessWidget {
  final String totalLabel;
  final String studentName;
  final String payerName;
  final List<FacturationConfirmAllocationItem> allocations;

  const _ConfirmBody({
    required this.totalLabel,
    required this.studentName,
    required this.payerName,
    required this.allocations,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.facturationCollectStepConfirm.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          l10n.facturationCreatePaymentConfirmCollectTitle(totalLabel),
          style: AppTextStyles.totalAmountLora.copyWith(
            fontSize: 22,
            color: AppColors.bleuProfond,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.facturationCreatePaymentConfirmSentence(
            totalLabel,
            studentName,
            payerName,
          ),
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          l10n.facturationCreatePaymentConfirmDistributionTitle,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _DistributionList(allocations: allocations),
      ],
    );
  }
}

/// Corps centré de l'étape 2 : processing / succès / échec.
class _ResultBody extends StatelessWidget {
  final _Phase phase;
  final String totalLabel;
  final String? incidentCode;

  const _ResultBody({
    required this.phase,
    required this.totalLabel,
    required this.incidentCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (kind, title, message) = switch (phase) {
      _Phase.success => (
        CollectResultKind.success,
        l10n.facturationCollectSuccessTitle,
        totalLabel,
      ),
      _Phase.error => (
        CollectResultKind.error,
        l10n.facturationCollectErrorTitle,
        l10n.facturationCollectErrorNoDebit,
      ),
      _ => (
        CollectResultKind.processing,
        l10n.facturationCollectProcessing,
        '',
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CollectResultMedallion(kind: kind),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (phase == _Phase.success) ...[
            const SizedBox(height: AppDimensions.spacingM),
            _ResultChip(
              icon: Icons.receipt_long_outlined,
              // Numéro de reçu absent côté backend → laissé vide pour le moment.
              label: l10n.facturationCollectReceiptChip('—'),
              color: AppColors.feeStatusPaid,
            ),
          ],
          if (phase == _Phase.error) ...[
            const SizedBox(height: AppDimensions.spacingM),
            _ResultChip(
              icon: Icons.report_gmailerrorred_outlined,
              label: l10n.facturationCollectIncidentChip(incidentCode ?? '—'),
              color: AppColors.danger,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pastille de résultat (Reçu n° / Code incident).
class _ResultChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ResultChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppDimensions.spacingS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.badge.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Répartition encadrée : une ligne par allocation (libellé + montant).
class _DistributionList extends StatelessWidget {
  final List<FacturationConfirmAllocationItem> allocations;

  const _DistributionList({required this.allocations});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          for (var i = 0; i < allocations.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      allocations[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Text(
                    allocations[i].amount,
                    style: AppTextStyles.moneyTabular.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (i < allocations.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}
