import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_modal_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_payer_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la modale d'encaissement (spec MODALE-12).
///
/// Réutilise le [PaymentsBloc] du détail (via [BlocProvider.value]) : le frais
/// encaissé alimente directement la liste des paiements. Au succès, on
/// redéclenche le chargement des paiements et des frais pour rafraîchir la page.
Future<void> showFacturationCreatePaymentDialog(
  BuildContext context, {
  required FacturationCreatePaymentIntent intent,
  required PaymentsBloc paymentsBloc,
  required StudentChargesBloc studentChargesBloc,
}) {
  void refreshDetail() {
    paymentsBloc.add(
      PaymentsRequested(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
      ),
    );
    studentChargesBloc.add(
      StudentChargesByAcademicYearRequested(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
      ),
    );
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<PaymentsBloc>.value(
      value: paymentsBloc,
      child: FacturationCreatePaymentDialogView(
        intent: intent,
        onPaymentCreated: refreshDetail,
      ),
    ),
  );
}

/// Contenu de la modale d'encaissement (état du formulaire + soumission).
class FacturationCreatePaymentDialogView extends StatefulWidget {
  final FacturationCreatePaymentIntent intent;
  final VoidCallback onPaymentCreated;

  const FacturationCreatePaymentDialogView({
    super.key,
    required this.intent,
    required this.onPaymentCreated,
  });

  @override
  State<FacturationCreatePaymentDialogView> createState() =>
      _FacturationCreatePaymentDialogViewState();
}

class _FacturationCreatePaymentDialogViewState
    extends State<FacturationCreatePaymentDialogView> {
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();

  late final List<_ChargeEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [
      for (final charge in widget.intent.unpaidCharges)
        if (chargeRemainingInCents(charge) > 0) _ChargeEntry(charge),
    ];
    for (final entry in _entries) {
      entry.controller.addListener(_onChanged);
    }
    _lastNameController.addListener(_onChanged);
    _firstNameController.addListener(_onChanged);
    _middleNameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String _formatPlain(int cents) {
    final amount = cents / 100;
    final isInteger = amount == amount.roundToDouble();
    return isInteger ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  }

  String _formatWithCurrency(int cents, String currency) =>
      formatMonetaryAmountWithCurrency(amount: cents / 100, currency: currency);

  void _onToggle(_ChargeEntry entry, bool value) {
    setState(() {
      entry.selected = value;
      if (value) {
        entry.controller.text = _formatPlain(entry.remainingInCents);
      } else {
        entry.controller.clear();
      }
    });
  }

  void _onSettleAll(_ChargeEntry entry) {
    setState(() {
      entry.controller.text = _formatPlain(entry.remainingInCents);
    });
  }

  int get _totalInCents =>
      _entries.fold<int>(0, (sum, entry) => sum + entry.effectiveCents);

  String get _currency {
    for (final entry in _entries) {
      if (entry.effectiveCents > 0 && entry.charge.currency.trim().isNotEmpty) {
        return entry.charge.currency.trim();
      }
    }
    for (final entry in _entries) {
      if (entry.charge.currency.trim().isNotEmpty) {
        return entry.charge.currency.trim();
      }
    }
    return '';
  }

  bool get _payerValid =>
      _lastNameController.text.trim().isNotEmpty &&
      _firstNameController.text.trim().isNotEmpty;

  String _studentFullName(AppLocalizations l10n) {
    final name = [
      widget.intent.lastName,
      widget.intent.surname,
      widget.intent.firstName,
    ].map((v) => v.trim()).where((v) => v.isNotEmpty).join(' ');
    return name.isEmpty ? l10n.facturationDetailUnknownValue : name;
  }

  String _payerFullName(AppLocalizations l10n) {
    final name = [
      _lastNameController.text,
      _middleNameController.text,
      _firstNameController.text,
    ].map((v) => v.trim()).where((v) => v.isNotEmpty).join(' ');
    return name.isEmpty ? l10n.facturationDetailUnknownValue : name;
  }

  Future<void> _onCollect(AppLocalizations l10n) async {
    final total = _totalInCents;
    final currency = _currency;
    if (!_payerValid || total <= 0 || currency.isEmpty) {
      return;
    }

    final retained = _entries.where((e) => e.effectiveCents > 0).toList();
    final bloc = context.read<PaymentsBloc>();

    final request = PaymentsCreateRequested(
      studentId: widget.intent.studentId,
      academicYearId: widget.intent.academicYearId,
      amountInCents: total,
      currency: currency,
      payerFirstName: _firstNameController.text.trim(),
      payerLastName: _lastNameController.text.trim(),
      payerMiddleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      allocations: [
        for (final entry in retained)
          CreatePaymentAllocationInput(
            studentChargeId: entry.charge.id,
            feeCode: entry.charge.feeCode,
            studentChargeLabel: entry.charge.label,
            amountInCents: entry.effectiveCents,
            currency: entry.charge.currency,
          ),
      ],
    );

    // La sur-couche 2 étapes porte la confirmation PUIS le résultat
    // (processing → succès | échec) : le paiement n'est créé qu'à l'étape
    // résultat et le toast est remplacé par la popin.
    final outcome = await showFacturationCreatePaymentConfirmDialog(
      context,
      paymentsBloc: bloc,
      totalLabel: _formatWithCurrency(total, currency),
      studentName: _studentFullName(l10n),
      payerName: _payerFullName(l10n),
      allocations: [
        for (final entry in retained)
          FacturationConfirmAllocationItem(
            label: entry.charge.feeCode.localizedFeeLabel(l10n),
            amount: _formatWithCurrency(
              entry.effectiveCents,
              entry.charge.currency,
            ),
          ),
      ],
      request: request,
    );

    if (!mounted) {
      return;
    }
    // Succès rendu par la popin résultat → on referme la modale d'encaissement,
    // PUIS on resynchronise le détail. La liste est déjà à jour (le bloc insère
    // le paiement) ; faire le refresh après fermeture évite qu'un éventuel échec
    // de rechargement ne contredise l'écran de succès.
    if (outcome == FacturationCollectOutcome.succeeded) {
      Navigator.of(context).maybePop();
      widget.onPaymentCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return BlocBuilder<PaymentsBloc, PaymentsState>(
      buildWhen: (prev, curr) => prev.createStatus != curr.createStatus,
      builder: (context, state) {
        final isLoading = state.createStatus == PaymentsStatus.loading;
        final total = _totalInCents;
        final currency = _currency;
        final canCollect = _payerValid && total > 0 && !isLoading;

        return Dialog(
          backgroundColor: AppColors.surfaceRaised,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppDimensions.facturationCreatePaymentModalMaxWidth,
              maxHeight: maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceModalDarkHeader(
                  eyebrow: l10n.facturationDetailCollectPaymentAction,
                  title: _studentFullName(l10n),
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                const FinanceModalGoldDivider(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FacturationCreatePaymentPayerSection(
                          lastNameController: _lastNameController,
                          firstNameController: _firstNameController,
                          middleNameController: _middleNameController,
                          readOnly: isLoading,
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                        _ChargesToSettle(
                          entries: _entries,
                          onToggle: isLoading ? null : _onToggle,
                          onSettleAll: isLoading ? null : _onSettleAll,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                _TotalBand(
                  label: l10n.facturationCreatePaymentTotalToCollect,
                  amount: _formatWithCurrency(total, currency),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  child: SizedBox(
                    width: double.infinity,
                    child: EteeloButton.primary(
                      label: l10n.facturationCreatePaymentCollectAmountAction(
                        _formatWithCurrency(total, currency),
                      ),
                      icon: Icons.account_balance_wallet_outlined,
                      isLoading: isLoading,
                      onPressed: canCollect ? () => _onCollect(l10n) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Entrée locale : un frais payable + son montant saisi + son état coché.
class _ChargeEntry {
  final StudentCharge charge;
  final TextEditingController controller;
  bool selected;

  _ChargeEntry(this.charge)
    : controller = TextEditingController(),
      selected = false;

  int get remainingInCents => chargeRemainingInCents(charge);

  int get effectiveCents => effectiveAllocationCents(
    selected: selected,
    rawAmount: controller.text,
    remainingInCents: remainingInCents,
  );

  void dispose() => controller.dispose();
}

/// Section « Frais à régler » : liste des lignes ou carte « tout soldé ».
class _ChargesToSettle extends StatelessWidget {
  final List<_ChargeEntry> entries;
  final void Function(_ChargeEntry entry, bool value)? onToggle;
  final void Function(_ChargeEntry entry)? onSettleAll;

  const _ChargesToSettle({
    required this.entries,
    required this.onToggle,
    required this.onSettleAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.facturationCreatePaymentChargesToSettleTitle,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.bleuProfond,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          l10n.facturationCreatePaymentChargesToSettleSubtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        if (entries.isEmpty)
          const _AllSettledCard()
        else
          for (var i = 0; i < entries.length; i++) ...[
            FacturationCreatePaymentChargeAllocationLine(
              charge: entries[i].charge,
              selected: entries[i].selected,
              amountController: entries[i].controller,
              onSelectedChanged: (v) => onToggle?.call(entries[i], v),
              onSettleAll: () => onSettleAll?.call(entries[i]),
            ),
            if (i < entries.length - 1)
              const SizedBox(height: AppDimensions.spacingS),
          ],
      ],
    );
  }
}

/// Carte « Tous les frais sont déjà soldés ».
class _AllSettledCard extends StatelessWidget {
  const _AllSettledCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.feeStatusPaidSoft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.feeStatusPaidBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: AppColors.feeStatusPaid,
            size: AppDimensions.detailHeaderIconSize,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.facturationCreatePaymentAllFeesSettled,
              style: AppTextStyles.body.copyWith(
                color: AppColors.feeStatusPaid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau sombre totalisant en direct : billet or-doux + total.
class _TotalBand extends StatelessWidget {
  final String label;
  final String amount;

  const _TotalBand({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bleuProfond,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingM,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: AppColors.orDoux,
            size: AppDimensions.detailHeaderIconSize,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: AppColors.textOnDark),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                amount,
                style: AppTextStyles.totalAmountLora.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
