import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_result_medallion.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_correction_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_modal_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_correction/payment_correction_reason_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre le geste « Annuler » sur un versement. Rend `true` quand
/// l'annulation a été écrite sur la tablette.
Future<bool> showFacturationPaymentCancelDialog(
  BuildContext context, {
  required String paymentId,
  required String amountLabel,
  required String dateLabel,
}) async {
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => BlocProvider<PaymentCorrectionCubit>(
      create: (_) => getIt<PaymentCorrectionCubit>(),
      child: FacturationPaymentCancelDialog(
        paymentId: paymentId,
        amountLabel: amountLabel,
        dateLabel: dateLabel,
      ),
    ),
  );
  return done ?? false;
}

/// La modale « Annuler un versement » : rappel de la différence avec
/// « Corriger », versement barré, motif, puis le résultat — toujours un succès
/// LOCAL, la synchronisation se lisant ensuite sur la ligne.
class FacturationPaymentCancelDialog extends StatefulWidget {
  final String paymentId;
  final String amountLabel;
  final String dateLabel;

  const FacturationPaymentCancelDialog({
    super.key,
    required this.paymentId,
    required this.amountLabel,
    required this.dateLabel,
  });

  @override
  State<FacturationPaymentCancelDialog> createState() =>
      _FacturationPaymentCancelDialogState();
}

class _FacturationPaymentCancelDialogState
    extends State<FacturationPaymentCancelDialog> {
  final _detail = TextEditingController();
  PaymentCorrectionReason? _reason;
  bool _cashMoved = false;

  @override
  void initState() {
    super.initState();
    _detail.addListener(_onChanged);
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSubmit {
    final reason = _reason;
    if (reason == null) return false;
    return !reason.requiresDetail || _detail.text.trim().isNotEmpty;
  }

  void _submit() {
    final reason = _reason;
    if (reason == null) return;
    context.read<PaymentCorrectionCubit>().submit(
      PaymentCorrectionDraft(
        paymentId: widget.paymentId,
        reason: reason,
        reasonDetail: _detail.text,
        cashMoved: _cashMoved,
      ),
    );
  }

  void _select(PaymentCorrectionReason reason) => setState(() {
    _reason = reason;
    // « Argent rendu » dit déjà que de l'argent a bougé ; la case reste
    // modifiable.
    if (reason == PaymentCorrectionReason.refunded) _cashMoved = true;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.facturationModalMaxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: BlocBuilder<PaymentCorrectionCubit, PaymentCorrectionState>(
          buildWhen: (a, b) => a != b,
          builder: (context, state) =>
              state.phase == PaymentCorrectionPhase.succeeded
              ? _Done(onClose: () => Navigator.of(context).pop(true))
              : _form(context, l10n, state),
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    PaymentCorrectionState state,
  ) {
    final busy = state.isSubmitting;
    return EteeloDialogBody(
      minPinnedHeight: 300,
      header: EteeloDialogDarkHeader(
        eyebrow: l10n.paymentCorrectionCancelTitle,
        title: widget.amountLabel,
        onClose: () => Navigator.of(context).pop(false),
      ),
      headerDividers: const [EteeloDialogGoldDivider()],
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingM),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentCorrectionCancelIntro,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _StruckRecap(amount: widget.amountLabel, date: widget.dateLabel),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.paymentCorrectionCancelConsequence,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          PaymentCorrectionReasonSection(
            gesture: PaymentCorrectionGesture.cancel,
            selected: _reason,
            onSelected: _select,
            detailController: _detail,
            cashMoved: _cashMoved,
            onCashMovedChanged: (v) => setState(() => _cashMoved = v),
            enabled: !busy,
          ),
          if (state.failure case final failure?)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingS),
              child: Text(
                l10n.paymentCorrectionFailed(failure.message),
                style: AppTextStyles.body.copyWith(color: AppColors.danger),
              ),
            ),
        ],
      ),
      footer: [
        const Divider(height: 1, color: AppColors.border),
        FinanceModalFooter(
          secondaryLabel: l10n.paymentCorrectionBack,
          secondaryIcon: Icons.arrow_back_rounded,
          onSecondary: busy ? null : () => Navigator.of(context).pop(false),
          primaryLabel: l10n.paymentCorrectionCancelAction,
          primaryIcon: Icons.block_rounded,
          onPrimary: _canSubmit && !busy ? _submit : null,
        ),
      ],
    );
  }
}

/// Le versement qui va être annulé, déjà barré.
class _StruckRecap extends StatelessWidget {
  final String amount;
  final String date;

  const _StruckRecap({required this.amount, required this.date});

  @override
  Widget build(BuildContext context) {
    final struck = AppTextStyles.bodyStrong.copyWith(
      color: AppColors.textMuted,
      decoration: TextDecoration.lineThrough,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(date, style: struck)),
          Text(amount, style: struck),
        ],
      ),
    );
  }
}

/// Le résultat : toujours un succès local. L'incertitude porte sur la
/// synchronisation, et elle se dit par une note, jamais par un échec.
class _Done extends StatelessWidget {
  final VoidCallback onClose;

  const _Done({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EteeloResultMedallion(kind: EteeloResultKind.success),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.paymentCorrectionCancelledDone,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.paymentCorrectionSavedOnTablet,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FilledButton(
            key: const ValueKey('payment-correction-done-close'),
            onPressed: onClose,
            child: Text(l10n.facturationPaymentCloseLabel),
          ),
        ],
      ),
    );
  }
}
