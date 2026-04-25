import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
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

  void _showPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pageUnderConstruction)),
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
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.financeDetailGradientStart,
              AppColors.financeDetailGradientMiddle,
              AppColors.financeDetailGradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: AppDimensions.financeDetailOrbLargeTop,
              right: AppDimensions.financeDetailOrbLargeRight,
              child: Container(
                width: AppDimensions.financeDetailOrbLargeSize,
                height: AppDimensions.financeDetailOrbLargeSize,
                decoration: BoxDecoration(
                  color: AppColors.financeDetailAccent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: AppDimensions.financeDetailOrbMediumTop,
              left: AppDimensions.financeDetailOrbMediumLeft,
              child: Container(
                width: AppDimensions.financeDetailOrbMediumSize,
                height: AppDimensions.financeDetailOrbMediumSize,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.detailContentMaxWidth,
                  ),
                  child: Column(
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
                      const SizedBox(height: AppDimensions.detailSectionSpacing),
                      if (!intent.hasDisplayContext)
                        _ContextErrorCard(
                          title: l10n.facturationDetailContextErrorTitle,
                          message: l10n.facturationDetailContextErrorMessage,
                        )
                      else
                        FacturationDetailDataLoader(
                          intent: intent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FacturationDetailPaymentsSection(
                                studentId: intent.studentId,
                                academicYearId: intent.academicYearId,
                                onCreatePaymentRequested: () =>
                                    _showPlaceholder(context),
                                onViewPaymentRequested: (payment) =>
                                    _openPaymentDetail(context, payment),
                              ),
                              const SizedBox(
                                height: AppDimensions.detailSectionSpacing,
                              ),
                              FacturationDetailChargesSection(
                                studentId: intent.studentId,
                                academicYearId: intent.academicYearId,
                                onViewChargeRequested: (StudentCharge _) =>
                                    _showPlaceholder(context),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextErrorCard extends StatelessWidget {
  final String title;
  final String message;

  const _ContextErrorCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
      decoration: BoxDecoration(
        color: AppColors.financeDetailCard,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.financeDetailCardShadowBlur,
            offset: Offset(0, AppDimensions.financeDetailCardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
