import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class FinanceStudentSummaryCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;
  final String unknownValue;
  final Widget? trailing;

  const FinanceStudentSummaryCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
    required this.unknownValue,
    this.trailing,
  });

  String get _fullName {
    final values = [lastName, firstName, surname]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (values.isEmpty) {
      return unknownValue;
    }

    return values.join(' ');
  }

  String get _classCycleLabel {
    final values = [levelName, levelGroupName]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (values.isEmpty) {
      return unknownValue;
    }

    return values.join(' · ');
  }

  String get _initials {
    final values = [firstName, lastName, surname]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(2)
        .map((value) => value.characters.first.toUpperCase())
        .join();

    return values.isEmpty ? '?' : values;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < AppDimensions.detailCompactBreakpoint;

          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
                child: Text(
                  _initials,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.bleuArdoise,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      style: AppTextStyles.totalAmountLora.copyWith(
                        fontSize: 20,
                        color: AppColors.bleuArdoise,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      _classCycleLabel,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (trailing == null) {
            return identity;
          }

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppDimensions.spacingM),
                trailing!,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppDimensions.spacingL),
              Container(
                width: 1,
                height: 72,
                color: AppColors.borderStrong.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppDimensions.spacingL),
              Flexible(child: trailing!),
            ],
          );
        },
      ),
    );
  }
}
