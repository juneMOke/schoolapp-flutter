import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_allocations_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_footer_actions.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_summary_strip.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationPaymentDetailPage extends StatelessWidget {
  final FacturationPaymentDetailIntent intent;

  static const Duration _entranceDuration = FinanceMotion.entrance;

  const FacturationPaymentDetailPage({super.key, required this.intent});

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

  void _onActionRequested(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.pageUnderConstruction)));
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

    return BlocProvider<PaymentsBloc>(
      create: (_) {
        final bloc = getIt<PaymentsBloc>();
        if (intent.paymentId.trim().isNotEmpty) {
          bloc.add(PaymentsAllocationsRequested(paymentId: intent.paymentId));
        }
        return bloc;
      },
      child: AppPageBackground(
        appBar: FinanceDetailAppBar(
          title: l10n.facturationPaymentDetailHeroTitle,
          subtitle: '$studentFullName · $studentSubtitle',
          fallbackRoute: AppRoutesNames.facturations,
        ),
        bottomNavigationBar: intent.hasDisplayContext
            ? _buildEntrance(
                intervalStart: 0.4,
                child: FacturationPaymentFooterActions(
                  downloadLabel: l10n.facturationPaymentDownloadPdfLabel,
                  printLabel: l10n.facturationPrintReceiptLabel,
                  onDownloadPdf: () => _onActionRequested(context),
                  onPrintReceipt: () => _onActionRequested(context),
                ),
              )
            : null,
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
                      title: l10n.facturationDetailContextErrorTitle,
                      message: l10n.facturationDetailContextErrorMessage,
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
                        child: FacturationPaymentSummaryStrip(
                          payerLabel: l10n.facturationPaymentPayerLabel,
                          amountLabel: l10n.facturationPaymentAmountLabel,
                          paidAtLabel: l10n.facturationPaymentPaidAtLabel,
                          unknownValue: l10n.facturationDetailUnknownValue,
                          payerFirstName: intent.payerFirstName,
                          payerLastName: intent.payerLastName,
                          payerMiddleName: intent.payerMiddleName,
                          amountInCents: intent.amountInCents,
                          currency: intent.currency,
                          paidAt: intent.paidAt,
                        ),
                      ),
                      SizedBox(height: blockSpacing),
                      _buildEntrance(
                        intervalStart: 0.2,
                        child: FacturationPaymentAllocationsSection(
                          paymentId: intent.paymentId,
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
