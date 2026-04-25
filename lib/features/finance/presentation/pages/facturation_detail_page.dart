import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_data_loader.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_payments_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_back_button.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_student_hero_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationDetailPage extends StatelessWidget {
  final FacturationDetailIntent intent;

  const FacturationDetailPage({super.key, required this.intent});

  void _openCreatePayment(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chargesState = context.read<StudentChargesBloc>().state;

    if (chargesState.status != StudentChargesStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.facturationCreatePaymentChargesUnavailable)),
      );
      return;
    }

    final unpaid = chargesState.studentCharges
        .where((c) => c.status != StudentChargeStatus.paid)
        .toList();

    if (unpaid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.facturationCreatePaymentNoChargesAvailable)),
      );
      return;
    }

    context.push(
      AppRoutesNames.facturationCreatePaymentPath(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
      ),
      extra: FacturationCreatePaymentIntent(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        studentCharges: chargesState.studentCharges,
      ),
    );
  }

  void _openChargeDetail(BuildContext context, StudentCharge charge) {
    context.push(
      AppRoutesNames.facturationChargeDetailPath(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        chargeId: charge.id,
      ),
      extra: FacturationChargeDetailIntent(
        chargeId: charge.id,
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        chargeLabel: charge.label,
        expectedAmountInCents: charge.expectedAmountInCents,
        amountPaidInCents: charge.amountPaidInCents,
        currency: charge.currency,
        chargeStatus: charge.status,
      ),
    );
  }

  void _openPaymentDetail(BuildContext context, Payment payment) {
    context.push(
      AppRoutesNames.facturationPaymentDetailPath(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        paymentId: payment.id,
      ),
      extra: FacturationPaymentDetailIntent(
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentsBloc>(create: (_) => getIt<PaymentsBloc>()),
        BlocProvider<StudentChargesBloc>(
          create: (_) => getIt<StudentChargesBloc>(),
        ),
      ],
      child: FinancePageBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
            final blockSpacing = compact
                ? AppDimensions.spacingM
                : AppDimensions.detailSectionSpacing;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceDetailBackButton(
                  label: l10n.facturationDetailBackLabel,
                  fallbackRoute: AppRoutesNames.facturations,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                FinanceStudentHeroCard(
                  title: l10n.facturationDetailInfoTitle,
                  subtitle: l10n.facturationDetailInfoSubtitle,
                  unknownValue: l10n.facturationDetailUnknownValue,
                  firstName: intent.firstName,
                  lastName: intent.lastName,
                  surname: intent.surname,
                  levelName: intent.levelName,
                  levelGroupName: intent.levelGroupName,
                  levelLabel: l10n.facturationDetailStudentLevel,
                  levelGroupLabel: l10n.facturationDetailStudentLevelGroup,
                  showFeatureChips: true,
                  paymentsChipLabel: l10n.facturationDetailInfoChipPayments,
                  chargesChipLabel: l10n.facturationDetailInfoChipCharges,
                ),
                SizedBox(height: blockSpacing),
                if (!intent.hasDisplayContext)
                  FinanceContextErrorCard(
                    title: l10n.facturationDetailContextErrorTitle,
                    message: l10n.facturationDetailContextErrorMessage,
                    icon: Icons.report_problem_outlined,
                    accent: AppColors.warning,
                    accentSoft: AppColors.warning.withValues(alpha: 0.14),
                    borderColor: AppColors.warning.withValues(alpha: 0.2),
                  )
                else
                  FacturationDetailDataLoader(
                    intent: intent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (blocContext) =>
                              FacturationDetailPaymentsSection(
                                studentId: intent.studentId,
                                academicYearId: intent.academicYearId,
                                onCreatePaymentRequested: () =>
                                    _openCreatePayment(blocContext),
                                onViewPaymentRequested: (payment) =>
                                    _openPaymentDetail(blocContext, payment),
                              ),
                        ),
                        SizedBox(height: blockSpacing),
                        FacturationDetailChargesSection(
                          studentId: intent.studentId,
                          academicYearId: intent.academicYearId,
                          onViewChargeRequested: (charge) =>
                              _openChargeDetail(context, charge),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

