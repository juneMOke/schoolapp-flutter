import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charges_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_state_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charges_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationDetailChargesSection extends StatelessWidget {
  final String studentId;
  final String academicYearId;
  final ValueChanged<StudentCharge> onViewChargeRequested;

  const FacturationDetailChargesSection({
    super.key,
    required this.studentId,
    required this.academicYearId,
    required this.onViewChargeRequested,
  });

  void _retry(BuildContext context) {
    context.read<StudentChargesBloc>().add(
      StudentChargesByAcademicYearRequested(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FinanceSectionCard(
      gradientColors: const [
        AppColors.financeDetailChargesSurface,
        AppColors.financeDetailChargesSurfaceAlt,
      ],
      borderColor: AppColors.financeDetailChargesAccent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: Icons.receipt_long_outlined,
            title: l10n.facturationDetailChargesSectionTitle,
            accent: AppColors.financeDetailChargesAccent,
            accentSoft: AppColors.financeDetailChargesAccentSoft,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.facturationDetailChargesSectionSubtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          BlocConsumer<StudentChargesBloc, StudentChargesState>(
            listenWhen: (prev, curr) =>
                prev.status != curr.status || prev.errorType != curr.errorType,
            listener: (context, state) {
              if (state.status != StudentChargesStatus.failure) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorType.localizedMessage(l10n))),
              );
            },
            buildWhen: (prev, curr) =>
                prev.status != curr.status ||
                prev.studentCharges != curr.studentCharges ||
                prev.errorType != curr.errorType,
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: FinanceMotion.standard,
                switchInCurve: FinanceMotion.outCurve,
                switchOutCurve: FinanceMotion.inCurve,
                child: () {
                  if (state.status == StudentChargesStatus.loading) {
                    return const Center(
                      key: ValueKey('charges-loading'),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state.status == StudentChargesStatus.failure) {
                    return FinanceStateCard(
                      key: const ValueKey('charges-error'),
                      message: state.errorType.localizedMessage(l10n),
                      icon: Icons.error_outline,
                      accent: AppColors.warning,
                      accentSoft: AppColors.financeDetailWarningSoft,
                      actionLabel: l10n.facturationDetailChargesRetry,
                      onAction: () => _retry(context),
                    );
                  }

                  if (state.studentCharges.isEmpty) {
                    return FinanceStateCard(
                      key: const ValueKey('charges-empty'),
                      message: l10n.facturationDetailChargesEmpty,
                      icon: Icons.inbox_outlined,
                      accent: AppColors.textSecondary,
                      accentSoft: AppColors.financeDetailMutedSurface,
                    );
                  }

                  return FacturationChargesTable(
                    key: const ValueKey('charges-table'),
                    charges: state.studentCharges,
                    onViewRequested: onViewChargeRequested,
                  );
                }(),
              );
            },
          ),
        ],
      ),
    );
  }
}
