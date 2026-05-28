import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_allocations_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_footer_actions.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_summary_strip.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_header.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationChargeDetailPage extends StatelessWidget {
  final FacturationChargeDetailIntent intent;

  static const Duration _entranceDuration = FinanceMotion.entrance;

  const FacturationChargeDetailPage({super.key, required this.intent});

  String _studentFullName(AppLocalizations l10n) {
    final fullName = [
      intent.lastName,
      intent.firstName,
      intent.surname,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');
    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  String _studentSubtitle(AppLocalizations l10n) {
    final subtitle = [intent.levelName, intent.levelGroupName]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' · ');
    return subtitle.isEmpty ? l10n.facturationDetailUnknownValue : subtitle;
  }

  String _chargeLabel(AppLocalizations l10n) =>
      intent.feeCode.localizedFeeLabel(l10n);

  void _onPrintStatementsRequested(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.pageUnderConstruction)));
  }

  bool _hasAllocations(StudentChargesState state) {
    final allocations = state.allocationsByChargeId[intent.chargeId];
    return state.allocationsStatus == StudentChargesStatus.success &&
        allocations != null &&
        allocations.isNotEmpty;
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
    final studentFullName = _studentFullName(l10n);
    final studentSubtitle = _studentSubtitle(l10n);
    final chargeLabel = _chargeLabel(l10n);

    return BlocProvider<StudentChargesBloc>(
      create: (_) {
        final bloc = getIt<StudentChargesBloc>();
        if (intent.chargeId.trim().isNotEmpty) {
          bloc.add(
            StudentChargePaymentAllocationsRequested(chargeId: intent.chargeId),
          );
        }
        return bloc;
      },
      child: AppPageBackground(
        appBar: FinanceDetailAppBar(
          title: l10n.facturationChargeDetailHeroTitle,
          subtitle: '$studentFullName · $studentSubtitle',
          fallbackRoute: AppRoutesNames.facturations,
        ),
        bottomNavigationBar:
            BlocBuilder<StudentChargesBloc, StudentChargesState>(
              buildWhen: (prev, curr) =>
                  prev.allocationsStatus != curr.allocationsStatus,
              builder: (context, state) {
                if (!_hasAllocations(state)) {
                  return const SizedBox.shrink();
                }
                return _buildEntrance(
                  intervalStart: 0.4,
                  child: FacturationChargeFooterActions(
                    printLabel: l10n.facturationPrintStatementsLabel,
                    onPrintStatements: () =>
                        _onPrintStatementsRequested(context),
                  ),
                );
              },
            ),
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
                if (!intent.hasDisplayContext)
                  _buildEntrance(
                    intervalStart: 0,
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
                        intervalStart: 0,
                        child: FacturationChargeSummaryStrip(
                          chargeLabel: chargeLabel,
                          chargeStatus: intent.chargeStatus,
                          expectedAmountInCents: intent.expectedAmountInCents,
                          amountPaidInCents: intent.amountPaidInCents,
                          currency: intent.currency,
                        ),
                      ),
                      SizedBox(height: blockSpacing),
                      _buildEntrance(
                        intervalStart: 0.2,
                        child: FacturationChargeAllocationsSection(
                          chargeId: intent.chargeId,
                          paidAmountInCents: intent.amountPaidInCents,
                          currency: intent.currency,
                        ),
                      ),
                    ],
                  ),
                if (intent.hasDisplayContext)
                  const SizedBox(height: AppDimensions.fabListBottomPadding),
              ],
            );
          },
        ),
      ),
    );
  }
}
