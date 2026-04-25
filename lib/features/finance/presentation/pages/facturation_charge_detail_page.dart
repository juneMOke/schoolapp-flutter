import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_allocations_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_info_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_print_receipt_cta.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_back_button.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_student_hero_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationChargeDetailPage extends StatelessWidget {
  final FacturationChargeDetailIntent intent;

  static const Duration _entranceDuration = Duration(milliseconds: 260);

  const FacturationChargeDetailPage({super.key, required this.intent});

  void _onPrintStatementsRequested(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pageUnderConstruction)),
    );
  }

  Widget _buildEntrance({
    required Widget child,
    required double intervalStart,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _entranceDuration,
      curve: Interval(intervalStart, 1, curve: Curves.easeOutCubic),
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider<StudentChargesBloc>(
      create: (_) {
        final bloc = getIt<StudentChargesBloc>();
        if (intent.chargeId.trim().isNotEmpty) {
          bloc.add(
            StudentChargePaymentAllocationsRequested(
              chargeId: intent.chargeId,
            ),
          );
        }
        return bloc;
      },
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth <
                          AppDimensions.detailCompactBreakpoint;
                      final blockSpacing = compact
                          ? AppDimensions.spacingM
                          : AppDimensions.detailSectionSpacing;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEntrance(
                            intervalStart: 0,
                            child: FinanceDetailBackButton(
                              label: l10n.facturationChargeDetailBackLabel,
                              fallbackRoute: AppRoutesNames.facturations,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          _buildEntrance(
                            intervalStart: 0.1,
                            child: FinanceStudentHeroCard(
                              title: l10n.facturationChargeDetailHeroTitle,
                              subtitle:
                                  l10n.facturationChargeDetailHeroSubtitle,
                              unknownValue:
                                  l10n.facturationDetailUnknownValue,
                              firstName: intent.firstName,
                              lastName: intent.lastName,
                              surname: intent.surname,
                              levelName: intent.levelName,
                              levelGroupName: intent.levelGroupName,
                              levelLabel:
                                  l10n.facturationDetailStudentLevel,
                              levelGroupLabel:
                                  l10n.facturationDetailStudentLevelGroup,
                              showFeatureChips: false,
                              paymentsChipLabel: '',
                              chargesChipLabel: '',
                            ),
                          ),
                          SizedBox(height: blockSpacing),
                          if (!intent.hasDisplayContext)
                            _buildEntrance(
                              intervalStart: 0.2,
                              child: _ContextErrorCard(
                                title: l10n
                                    .facturationChargeDetailContextErrorTitle,
                                message: l10n
                                    .facturationChargeDetailContextErrorMessage,
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildEntrance(
                                  intervalStart: 0.2,
                                  child: FacturationChargeInfoSection(
                                    chargeLabel: intent.chargeLabel,
                                    expectedAmountInCents:
                                        intent.expectedAmountInCents,
                                    amountPaidInCents:
                                        intent.amountPaidInCents,
                                    currency: intent.currency,
                                    chargeStatus: intent.chargeStatus,
                                  ),
                                ),
                                SizedBox(height: blockSpacing),
                                _buildEntrance(
                                  intervalStart: 0.3,
                                  child: FacturationChargeAllocationsSection(
                                    chargeId: intent.chargeId,
                                    expectedAmountInCents:
                                        intent.amountPaidInCents,
                                    currency: intent.currency,
                                  ),
                                ),
                                SizedBox(height: blockSpacing),
                                _buildEntrance(
                                  intervalStart: 0.4,
                                  child: BlocBuilder<StudentChargesBloc,
                                      StudentChargesState>(
                                    buildWhen: (prev, curr) =>
                                        prev.allocationsStatus !=
                                            curr.allocationsStatus ||
                                        prev.allocationsByChargeId !=
                                            curr.allocationsByChargeId,
                                    builder: (context, state) {
                                      final allocations = state
                                          .allocationsByChargeId[intent.chargeId];
                                      final hasAllocations =
                                          state.allocationsStatus ==
                                              StudentChargesStatus.success &&
                                          allocations != null &&
                                          allocations.isNotEmpty;
                                      if (!hasAllocations) {
                                        return const SizedBox.shrink();
                                      }
                                      return FacturationPrintReceiptCta(
                                        label:
                                            l10n.facturationPrintStatementsLabel,
                                        subtitle: l10n
                                            .facturationPrintStatementsSubtitle,
                                        onPressed: () =>
                                            _onPrintStatementsRequested(context),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
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
