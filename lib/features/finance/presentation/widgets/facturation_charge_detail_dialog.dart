import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/finance_csv_export_helper.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_modal_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_allocations_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre le détail d'un frais en popin (spec §16) — même pattern que la popin
/// de détail d'un paiement.
Future<void> showFacturationChargeDetailDialog(
  BuildContext context, {
  required FacturationChargeDetailIntent intent,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => BlocProvider<StudentChargesBloc>(
      create: (_) {
        final bloc = getIt<StudentChargesBloc>();
        if (intent.chargeId.trim().isNotEmpty) {
          bloc.add(
            StudentChargePaymentAllocationsRequested(chargeId: intent.chargeId),
          );
        }
        return bloc;
      },
      child: Builder(
        builder: (blocContext) => FacturationChargeDetailDialogView(
          intent: intent,
          allocations: FacturationChargeAllocationsSection(
            chargeId: intent.chargeId,
            paidAmountInCents: intent.amountPaidInCents,
            currency: intent.currency,
          ),
          onPrintStatements: () => _exportChargeStatement(blocContext, intent),
        ),
      ),
    ),
  );
}

Future<void> _exportChargeStatement(
  BuildContext context,
  FacturationChargeDetailIntent intent,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final allocations =
      context
          .read<StudentChargesBloc>()
          .state
          .allocationsByChargeId[intent.chargeId] ??
      const [];

  if (allocations.isEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.facturationChargeStatementEmpty)),
    );
    return;
  }

  final csv = FinanceCsvExportHelper.buildChargeStatementCsv(
    l10n: l10n,
    allocations: allocations,
    currency: intent.currency,
  );

  await Clipboard.setData(ClipboardData(text: csv));
  if (!context.mounted) {
    return;
  }
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.facturationChargeStatementCopied)),
  );
}

/// Contenu visuel (pur, sans BLoC) de la popin de détail d'un frais.
class FacturationChargeDetailDialogView extends StatelessWidget {
  final FacturationChargeDetailIntent intent;
  final Widget allocations;
  final VoidCallback? onPrintStatements;

  const FacturationChargeDetailDialogView({
    super.key,
    required this.intent,
    required this.allocations,
    this.onPrintStatements,
  });

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  void _onPrint(BuildContext context) {
    if (onPrintStatements != null) {
      onPrintStatements!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.pageUnderConstruction),
      ),
    );
  }

  double get _progress {
    final expected = intent.expectedAmountInCents;
    if (expected <= 0) {
      return intent.amountPaidInCents > 0 ? 1 : 0;
    }
    return (intent.amountPaidInCents / expected).clamp(0.0, 1.0);
  }

  String _format(double cents, String currency) =>
      formatMonetaryAmountWithCurrency(amount: cents / 100, currency: currency);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final status = intent.chargeStatus;
    final remaining = (intent.expectedAmountInCents - intent.amountPaidInCents)
        .clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.facturationModalMaxWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FinanceModalDarkHeader(
              eyebrow: l10n.facturationChargeDetailHeroTitle,
              title: intent.feeCode.localizedFeeLabel(l10n),
              trailing: _StatusPill(
                status: status,
                label: status.localizedLabel(l10n),
              ),
              onClose: () => _close(context),
            ),
            const FinanceModalGoldDivider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressBar(progress: _progress, fill: status.badgeColor),
                    const SizedBox(height: AppDimensions.spacingM),
                    FinanceKeyValueRows(
                      rows: [
                        FinanceKeyValueRow(
                          icon: Icons.request_quote_outlined,
                          label:
                              l10n.facturationChargeDetailExpectedAmountLabel,
                          value: _format(
                            intent.expectedAmountInCents,
                            intent.currency,
                          ),
                        ),
                        FinanceKeyValueRow(
                          icon: Icons.payments_outlined,
                          label: l10n.facturationDetailHeaderKpiAlreadyPaid,
                          value: _format(
                            intent.amountPaidInCents,
                            intent.currency,
                          ),
                        ),
                        FinanceKeyValueRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label:
                              l10n.facturationChargeDetailRemainingAmountLabel,
                          value: _format(remaining, intent.currency),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    allocations,
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            FinanceModalFooter(
              secondaryLabel: l10n.facturationPrintStatementsLabel,
              secondaryIcon: Icons.download_outlined,
              onSecondary: () => _onPrint(context),
              primaryLabel: l10n.facturationPaymentCloseLabel,
              primaryIcon: Icons.check_rounded,
              onPrimary: () => _close(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille de statut du frais (Soldé / Partiel / Impayé) pour l'en-tête sombre.
class _StatusPill extends StatelessWidget {
  final StudentChargeStatus status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = status.badgeColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.24),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: AppColors.textOnDark),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.badge.copyWith(color: AppColors.textOnDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de progression du frais, teintée par le statut (même pattern que la
/// ligne de frais).
class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color fill;

  const _ProgressBar({required this.progress, required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 7,
        backgroundColor: AppColors.surfaceAlt,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }
}
