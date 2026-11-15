import 'package:dartz/dartz.dart' show Either, Left;
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_answer.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/closing_ledger.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_amount_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la modale envoie. Rend la clôture, ou l'échec.
typedef CloseRegister =
    Future<Either<Failure, CashClosure>> Function({
      required bool matches,
      required int shownExpectedInCents,
      int? declaredAmountInCents,
      String? justification,
    });

/// Clôturer une caisse (B5) : le point de la journée, puis une seule question,
/// « Avez-vous bien {reste} dans la caisse ? ». `null` si l'on annule ; sinon
/// la clôture, ou le refus qui ferme la modale (déjà clôturée).
Future<Either<Failure, CashClosure>?> showClosingDialog(
  BuildContext context, {
  required CashDaySummary summary,
  required DateTime date,
  required CloseRegister onClose,
  CashDaySummary? Function()? latest,
}) => EteeloFormDialog.show<Either<Failure, CashClosure>>(
  context,
  _ClosingDialog(
    summary: summary,
    date: date,
    onClose: onClose,
    latest: latest,
  ),
);

class _ClosingDialog extends StatefulWidget {
  final CashDaySummary summary;
  final DateTime date;
  final CloseRegister onClose;

  /// La journée relue après un refus : le point de la journée doit tomber
  /// juste avec le nouveau reste qu'on fait revérifier.
  final CashDaySummary? Function()? latest;

  const _ClosingDialog({
    required this.summary,
    required this.date,
    required this.onClose,
    this.latest,
  });

  @override
  State<_ClosingDialog> createState() => _ClosingDialogState();
}

class _ClosingDialogState extends State<_ClosingDialog> {
  /// Le reste montré. Si le serveur répond qu'il a bougé, on montre le
  /// nouveau et la réponse s'efface : la caissière revérifie.
  late var _summary = widget.summary;
  late var _shown = widget.summary.expectedInCents;
  ClosingAnswer? _answer;
  final _declared = TextEditingController();
  final _justification = TextEditingController();
  var _saving = false;
  var _showErrors = false;
  Failure? _failure;
  int? _movedFrom;

  @override
  void dispose() {
    _declared.dispose();
    _justification.dispose();
    super.dispose();
  }

  TreasuryCurrency get _currency => _summary.register.currency;

  int? get _declaredCents =>
      TreasuryAmountField.read(_declared.text, _currency);

  bool get _valid => CashClosingRules.canSubmit(
    answer: _answer,
    currency: _currency,
    shownExpectedInCents: _shown,
    declaredInCents: _declaredCents,
    justification: _justification.text,
  );

  Future<void> _submit() async {
    // Deux validations dans la même image (double Entrée) : un seul envoi.
    if (_saving) return;
    if (!_valid) {
      setState(() => _showErrors = true);
      return;
    }
    final matches = _answer == ClosingAnswer.matches;
    setState(() {
      _saving = true;
      _failure = null;
    });
    final result = await widget.onClose(
      matches: matches,
      shownExpectedInCents: _shown,
      declaredAmountInCents: matches ? null : _declaredCents,
      justification: matches ? null : _justification.text,
    );
    if (!mounted) return;
    result.fold(_refused, (closure) => Navigator.of(context).pop(result));
  }

  void _refused(Failure failure) {
    final refusal = failure is TreasuryRefusalFailure ? failure.refusal : null;
    if (refusal == TreasuryRefusal.cashDayAlreadyClosed) {
      // Quelqu'un d'autre a clôturé : on ne rejoue jamais, on montre.
      Navigator.of(context).pop(Left<Failure, CashClosure>(failure));
      return;
    }
    final fresh = widget.latest?.call();
    final serverExpected = refusal == TreasuryRefusal.expectedChanged
        ? (failure as TreasuryRefusalFailure).serverExpectedInCents ??
              fresh?.expectedInCents
        : null;
    setState(() {
      _saving = false;
      if (fresh != null) _summary = fresh;
      if (serverExpected != null) {
        _movedFrom = _shown;
        _shown = serverExpected;
        _answer = null;
        _failure = null;
      } else {
        _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summary;
    final failure = _failure;
    final movedFrom = _movedFrom;
    final differs = _answer == ClosingAnswer.differs;
    final VoidCallback? submit = _saving || !_valid ? null : _submit;
    // Ni la barrière, ni Échap, ni le retour ne ferment la modale pendant
    // l'envoi : la réponse du serveur doit être vue.
    return PopScope(
      canPop: !_saving,
      child: _form(context, l10n, summary, failure, movedFrom, differs, submit),
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    CashDaySummary summary,
    Failure? failure,
    int? movedFrom,
    bool differs,
    VoidCallback? submit,
  ) {
    return EteeloFormDialog(
      onSubmit: submit,
      maxWidth: AppDimensions.treasuryClosingModalMaxWidth,
      eyebrow: l10n.treasuryCloseEyebrow(widget.date),
      title: l10n.treasuryCloseTitle(summary.register.name),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClosingLedger(summary: summary, shownExpectedInCents: _shown),
          if (movedFrom != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.treasuryExpectedChangedMessage(
                TreasuryFormat.money(movedFrom, _currency),
                TreasuryFormat.money(_shown, _currency),
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.financeCrossedAccent,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ClosingAnswerPicker(
            shownExpected: TreasuryFormat.money(_shown, _currency),
            answer: _answer,
            enabled: !_saving,
            onChanged: (answer) => setState(() => _answer = answer),
          ),
          if (differs) ...[
            const SizedBox(height: AppSpacing.lg),
            ClosingDifference(
              currency: _currency,
              shownExpectedInCents: _shown,
              declared: _declared,
              justification: _justification,
              enabled: !_saving,
              showErrors: _showErrors,
              onChanged: () => setState(() {}),
              onPickYes: () => setState(() => _answer = ClosingAnswer.matches),
            ),
          ],
          if (_answer != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.treasuryLockWarning,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.financeCrossedAccent,
              ),
            ),
          ],
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.treasurySaveFailed(l10n.treasuryFailureReason(failure)),
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.secondary(
          label: l10n.treasuryCancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        if (differs)
          EteeloButton.danger(
            label: l10n.treasuryCloseWithGap,
            icon: Icons.lock_outline,
            isLoading: _saving,
            onPressed: submit,
            fullWidth: false,
          )
        else
          EteeloButton.primary(
            label: l10n.treasuryCloseButton,
            icon: Icons.lock_outline,
            isLoading: _saving,
            onPressed: submit,
            fullWidth: false,
          ),
      ],
    );
  }
}
