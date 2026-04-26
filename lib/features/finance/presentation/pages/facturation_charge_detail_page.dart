import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_allocations_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_info_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_print_receipt_cta.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_back_button.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_student_hero_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationChargeDetailPage extends StatelessWidget {
  final FacturationChargeDetailIntent intent;

  static const Duration _entranceDuration = FinanceMotion.entrance;

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
      curve: Interval(intervalStart, 1, curve: FinanceMotion.outCurve),
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
                    subtitle: l10n.facturationChargeDetailHeroSubtitle,
                    unknownValue: l10n.facturationDetailUnknownValue,
                    firstName: intent.firstName,
                    lastName: intent.lastName,
                    surname: intent.surname,
                    levelName: intent.levelName,
                    levelGroupName: intent.levelGroupName,
                    levelLabel: l10n.facturationDetailStudentLevel,
                    levelGroupLabel: l10n.facturationDetailStudentLevelGroup,
                    showFeatureChips: false,
                    paymentsChipLabel: l10n.facturationDetailInfoChipPayments,
                    chargesChipLabel: l10n.facturationDetailInfoChipCharges,
                  ),
                ),
                SizedBox(height: blockSpacing),
                if (!intent.hasDisplayContext)
                  _buildEntrance(
                    intervalStart: 0.2,
                    child: FinanceContextErrorCard(
                      title: l10n.facturationChargeDetailContextErrorTitle,
                      message: l10n.facturationChargeDetailContextErrorMessage,
                      icon: Icons.report_problem_outlined,
                      accent: AppColors.warning,
                      accentSoft: AppColors.warning.withValues(alpha: 0.14),
                      borderColor: AppColors.warning.withValues(alpha: 0.2),
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
                          expectedAmountInCents: intent.expectedAmountInCents,
                          amountPaidInCents: intent.amountPaidInCents,
                          currency: intent.currency,
                          chargeStatus: intent.chargeStatus,
                        ),
                      ),
                      SizedBox(height: blockSpacing),
                      _buildEntrance(
                        intervalStart: 0.3,
                        child: FacturationChargeAllocationsSection(
                          chargeId: intent.chargeId,
                          expectedAmountInCents: intent.amountPaidInCents,
                          currency: intent.currency,
                        ),
                      ),
                      SizedBox(height: blockSpacing),
                      _buildEntrance(
                        intervalStart: 0.4,
                        child: BlocBuilder<StudentChargesBloc,
                            StudentChargesState>(
                          buildWhen: (prev, curr) =>
                              prev.allocationsStatus != curr.allocationsStatus ||
                              prev.allocationsByChargeId !=
                                  curr.allocationsByChargeId,
                          builder: (context, state) {
                            final allocations =
                                state.allocationsByChargeId[intent.chargeId];
                            final hasAllocations =
                                state.allocationsStatus ==
                                    StudentChargesStatus.success &&
                                allocations != null &&
                                allocations.isNotEmpty;
                            if (!hasAllocations) {
                              return const SizedBox.shrink();
                            }
                            return FacturationPrintReceiptCta(
                              label: l10n.facturationPrintStatementsLabel,
                              subtitle: l10n.facturationPrintStatementsSubtitle,
                              onPressed: () => _onPrintStatementsRequested(context),
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
    );
  }
}
