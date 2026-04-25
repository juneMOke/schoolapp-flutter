import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charges_error_l10n_extension.dart';
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.financeDetailChargesSurface,
            AppColors.financeDetailChargesSurfaceAlt,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(
          color: AppColors.financeDetailChargesAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.spacingL,
                height: AppDimensions.spacingL,
                decoration: BoxDecoration(
                  color: AppColors.financeDetailChargesAccentSoft,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: AppDimensions.detailMiniIconSize,
                  color: AppColors.financeDetailChargesAccent,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.facturationDetailChargesSectionTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.financeDetailChargesAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
              if (state.status == StudentChargesStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == StudentChargesStatus.failure) {
                return _ErrorCard(
                  message: state.errorType.localizedMessage(l10n),
                  retryLabel: l10n.facturationDetailChargesRetry,
                  onRetry: () => _retry(context),
                );
              }

              if (state.studentCharges.isEmpty) {
                return _EmptyCard(message: l10n.facturationDetailChargesEmpty);
              }

              return FacturationChargesTable(
                charges: state.studentCharges,
                onViewRequested: onViewChargeRequested,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.financeDetailMutedSurface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.financeDetailMutedSurface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
