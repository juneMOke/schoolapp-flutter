import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/state_card.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charges_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
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
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              final partialCount = state.studentCharges
                  .where(
                    (charge) => charge.status == StudentChargeStatus.partial,
                  )
                  .length;
              final dueCount = state.studentCharges
                  .where((charge) => charge.status == StudentChargeStatus.due)
                  .length;

              final subtitle = state.status == StudentChargesStatus.success
                  ? l10n.facturationDetailChargesSummary(
                      state.studentCharges.length,
                      partialCount,
                      dueCount,
                    )
                  : l10n.facturationDetailChargesSectionSubtitle;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(subtitle: subtitle),
                  const SizedBox(height: AppDimensions.spacingM),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppDimensions.spacingM),
                  AnimatedSwitcher(
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
                        return StateCard(
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
                        return StateCard(
                          key: const ValueKey('charges-empty'),
                          message: l10n.facturationDetailChargesEmpty,
                          icon: Icons.inbox_outlined,
                          accent: AppColors.textSecondary,
                          accentSoft: AppColors.surfaceAlt,
                        );
                      }

                      return FacturationChargesTable(
                        key: const ValueKey('charges-table'),
                        charges: state.studentCharges,
                        onViewRequested: onViewChargeRequested,
                      );
                    }(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String subtitle;

  const _SectionHeader({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: AppDimensions.spacingXL,
          height: AppDimensions.spacingXL,
          child: Icon(
            Icons.receipt_long_outlined,
            size: AppDimensions.detailHeaderIconSize,
            color: AppColors.bleuArdoise,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Row(
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.facturationDetailChargesSectionTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
