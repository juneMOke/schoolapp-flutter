import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_data_loader.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_detail_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_payments_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationDetailPage extends StatelessWidget {
  final FacturationDetailIntent intent;

  const FacturationDetailPage({super.key, required this.intent});

  String _studentFullName(AppLocalizations l10n) {
    final fullName = [
      intent.lastName,
      intent.firstName,
      intent.surname,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');

    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  /// Classe affichée dans le sur-titre « Facturation · {classe} » (spec §06).
  String _classLabel(AppLocalizations l10n) {
    final value = intent.levelName.trim().isNotEmpty
        ? intent.levelName.trim()
        : intent.levelGroupName.trim();
    return value.isEmpty ? l10n.facturationDetailUnknownValue : value;
  }

  String _formatAmountOnly(double cents) {
    return formatMonetaryAmount(cents / 100);
  }

  void _openCreatePayment(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chargesState = context.read<StudentChargesBloc>().state;

    if (chargesState.status != StudentChargesStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.facturationCreatePaymentChargesUnavailable),
        ),
      );
      return;
    }

    final unpaid = chargesState.studentCharges
        .where((c) => c.status != StudentChargeStatus.paid)
        .toList();

    if (unpaid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.facturationCreatePaymentNoChargesAvailable),
        ),
      );
      return;
    }

    showFacturationCreatePaymentDialog(
      context,
      intent: FacturationCreatePaymentIntent(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        studentCharges: chargesState.studentCharges,
      ),
      paymentsBloc: context.read<PaymentsBloc>(),
      studentChargesBloc: context.read<StudentChargesBloc>(),
    );
  }

  void _openChargeDetail(BuildContext context, StudentCharge charge) {
    // Détail d'un frais ouvert en popin (spec §16), au-dessus de la page.
    showFacturationChargeDetailDialog(
      context,
      intent: FacturationChargeDetailIntent(
        chargeId: charge.id,
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        feeCode: charge.feeCode,
        expectedAmountInCents: charge.expectedAmountInCents,
        amountPaidInCents: charge.amountPaidInCents,
        currency: charge.currency,
        chargeStatus: charge.status,
      ),
    );
  }

  void _openPaymentDetail(BuildContext context, Payment payment) {
    // Détail d'un paiement ouvert en popin (spec §15), au-dessus de la page.
    showFacturationPaymentDetailDialog(
      context,
      intent: FacturationPaymentDetailIntent(
        paymentId: payment.id,
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        payerFirstName: payment.payerFirstName,
        payerLastName: payment.payerLastName,
        payerMiddleName: payment.payerMiddleName,
        amountInCents: payment.amountInCents,
        currency: payment.currency,
        paidAt: payment.paidAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final studentFullName = _studentFullName(l10n);

    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentsBloc>(create: (_) => getIt<PaymentsBloc>()),
        BlocProvider<StudentChargesBloc>(
          create: (_) => getIt<StudentChargesBloc>(),
        ),
      ],
      child: AppPageBackground(
        appBar: FacturationDetailAppBar(
          fullName: studentFullName,
          eyebrow: '${l10n.facturationDetailEyebrow} · ${_classLabel(l10n)}',
          firstName: intent.firstName,
          lastName: intent.lastName,
          fallbackRoute: AppRoutesNames.facturations,
          trailing: const _BillingBalanceAppBarPill(),
        ),
        child: LayoutBuilder(
          builder: (context, available) {
            // Grand écran : on élargit le contenu (1180) pour juxtaposer
            // Paiements | Frais ; en dessous, largeur de lecture conservée (880).
            final wide =
                available.maxWidth >= AppBreakpoints.financeDetailTwoColMin;
            final contentMaxWidth = wide
                ? AppDimensions.detailContentMaxWidth
                : AppDimensions.facturationContentMaxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth <
                        AppDimensions.detailCompactBreakpoint;
                    final twoCol =
                        constraints.maxWidth >=
                        AppBreakpoints.financeDetailTwoColMin;
                    final blockSpacing = compact
                        ? AppDimensions.spacingM
                        : AppDimensions.detailSectionSpacing;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<StudentChargesBloc, StudentChargesState>(
                          buildWhen: (prev, curr) =>
                              prev.status != curr.status ||
                              prev.studentCharges != curr.studentCharges,
                          builder: (context, state) {
                            final hasCharges =
                                state.status == StudentChargesStatus.success &&
                                state.studentCharges.isNotEmpty;
                            final totalDue = hasCharges
                                ? state.studentCharges.fold<double>(
                                    0.0,
                                    (sum, charge) =>
                                        sum + charge.expectedAmountInCents,
                                  )
                                : 0.0;
                            final alreadyPaid = hasCharges
                                ? state.studentCharges.fold<double>(
                                    0.0,
                                    (sum, charge) =>
                                        sum + charge.amountPaidInCents,
                                  )
                                : 0.0;
                            final remaining = (totalDue - alreadyPaid)
                                .toDouble();
                            final currency = hasCharges
                                ? state.studentCharges.first.currency
                                : '';

                            // Tuiles de synthèse affichées directement sur la page
                            // (l'identité élève + classe vit déjà dans l'AppBar).
                            return FinanceDetailKpiStrip(
                              items: [
                                FinanceDetailKpiItem(
                                  label:
                                      l10n.facturationDetailHeaderKpiTotalDue,
                                  value: hasCharges
                                      ? _formatAmountOnly(totalDue)
                                      : l10n.facturationDetailUnknownValue,
                                  suffix: hasCharges ? currency : null,
                                  valueColor: AppColors.bleuArdoise,
                                  topAccentColor: AppColors.bleuArdoise,
                                ),
                                FinanceDetailKpiItem(
                                  label: l10n
                                      .facturationDetailHeaderKpiAlreadyPaid,
                                  value: hasCharges
                                      ? _formatAmountOnly(alreadyPaid)
                                      : l10n.facturationDetailUnknownValue,
                                  suffix: hasCharges ? currency : null,
                                  valueColor: AppColors.feeStatusPaid,
                                  topAccentColor: AppColors.feeStatusPaid,
                                ),
                                FinanceDetailKpiItem(
                                  label:
                                      l10n.facturationDetailHeaderKpiRemaining,
                                  value: hasCharges
                                      ? _formatAmountOnly(remaining)
                                      : l10n.facturationDetailUnknownValue,
                                  suffix: hasCharges ? currency : null,
                                  valueColor: remaining > 0
                                      ? AppColors.feeStatusDue
                                      : AppColors.feeStatusPaid,
                                  topAccentColor: remaining > 0
                                      ? AppColors.feeStatusDue
                                      : AppColors.feeStatusPaid,
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: blockSpacing),
                        if (!intent.hasDisplayContext)
                          FinanceContextErrorCard(
                            title: l10n.facturationDetailContextErrorTitle,
                            message: l10n.facturationDetailContextErrorMessage,
                            icon: Icons.report_problem_outlined,
                            accent: AppColors.warning,
                            accentSoft: AppColors.warning.withValues(
                              alpha: 0.14,
                            ),
                            borderColor: AppColors.warning.withValues(
                              alpha: 0.2,
                            ),
                          )
                        else
                          FacturationDetailDataLoader(
                            intent: intent,
                            child: Builder(
                              builder: (blocContext) {
                                final payments =
                                    FacturationDetailPaymentsSection(
                                      studentId: intent.studentId,
                                      academicYearId: intent.academicYearId,
                                      onCreatePaymentRequested: () =>
                                          _openCreatePayment(blocContext),
                                      onViewPaymentRequested: (payment) =>
                                          _openPaymentDetail(
                                            blocContext,
                                            payment,
                                          ),
                                    );
                                final charges = FacturationDetailChargesSection(
                                  studentId: intent.studentId,
                                  academicYearId: intent.academicYearId,
                                  onViewChargeRequested: (charge) =>
                                      _openChargeDetail(blocContext, charge),
                                );

                                // Grand écran : Paiements et Frais côte à côte.
                                if (twoCol) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: payments),
                                      SizedBox(width: blockSpacing),
                                      Expanded(child: charges),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    payments,
                                    SizedBox(height: blockSpacing),
                                    charges,
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pastille de solde rendue dans l'AppBar (spec §06).
///
/// Vit dans le sous-arbre du [MultiBlocProvider] de la page, donc le
/// [StudentChargesBloc] est bien accessible depuis l'AppBar.
class _BillingBalanceAppBarPill extends StatelessWidget {
  const _BillingBalanceAppBarPill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<StudentChargesBloc, StudentChargesState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.studentCharges != curr.studentCharges,
      builder: (context, state) {
        final hasCharges =
            state.status == StudentChargesStatus.success &&
            state.studentCharges.isNotEmpty;
        if (!hasCharges) {
          return const SizedBox.shrink();
        }

        final totalDue = state.studentCharges.fold<double>(
          0.0,
          (sum, charge) => sum + charge.expectedAmountInCents,
        );
        final alreadyPaid = state.studentCharges.fold<double>(
          0.0,
          (sum, charge) => sum + charge.amountPaidInCents,
        );
        final remaining = totalDue - alreadyPaid;
        final hasBalance = remaining > 0;
        final amount = formatMonetaryAmountWithCurrency(
          amount: remaining / 100,
          currency: state.studentCharges.first.currency,
        );

        return FacturationBalancePill(
          hasBalance: hasBalance,
          label: hasBalance
              ? l10n.facturationBalanceDuePill(amount)
              : l10n.facturationBalanceUpToDatePill,
        );
      },
    );
  }
}
