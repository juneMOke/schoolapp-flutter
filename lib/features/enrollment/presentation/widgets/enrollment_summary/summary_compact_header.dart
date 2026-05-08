import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_mini_avatar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_step_constants.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryCompactHeader extends StatelessWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;

  const SummaryCompactHeader({super.key, required this.enrollmentDetail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = enrollmentDetail.studentDetail;

    return BlocBuilder<StudentChargesBloc, StudentChargesState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.studentCharges != curr.studentCharges,
      builder: (context, state) {
        final charges = state.studentCharges;
        final total = charges.fold<double>(
          0,
          (sum, charge) => sum + charge.expectedAmountInCents,
        );
        final currency = charges.isNotEmpty ? charges.first.currency : '';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: const BoxDecoration(
            color: AppColors.papier,
            borderRadius: AppRadius.brMd,
            border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth < enrollmentSummaryCompactBreakpoint;

              final identity = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        student.firstName,
                        student.lastName,
                        student.surname,
                      ].where((part) => part.trim().isNotEmpty).join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '${l10n.dateOfBirth}: ${student.dateOfBirth}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '${l10n.targetLevelLabel}: ${student.schoolLevel.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );

              final totalBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.summaryChargesTotalDue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    formatMonetaryAmountWithCurrency(
                      amount: total,
                      currency: currency,
                    ),
                    style: AppTextStyles.totalAmountLora.copyWith(
                      color: AppColors.terreCuite,
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SummaryMiniAvatar(
                          firstName: student.firstName,
                          lastName: student.lastName,
                          size: 52,
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        identity,
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    totalBlock,
                  ],
                );
              }

              return Row(
                children: [
                  SummaryMiniAvatar(
                    firstName: student.firstName,
                    lastName: student.lastName,
                    size: 52,
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  identity,
                  Container(width: 1, height: 48, color: AppColors.border),
                  const SizedBox(width: AppDimensions.spacingM),
                  totalBlock,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
