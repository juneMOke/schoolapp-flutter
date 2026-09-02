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
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_grouping.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_group_accordion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationDetailChargesSection extends StatefulWidget {
  final String studentId;
  final String academicYearId;
  final ValueChanged<StudentCharge> onViewChargeRequested;

  const FacturationDetailChargesSection({
    super.key,
    required this.studentId,
    required this.academicYearId,
    required this.onViewChargeRequested,
  });

  @override
  State<FacturationDetailChargesSection> createState() =>
      _FacturationDetailChargesSectionState();
}

class _FacturationDetailChargesSectionState
    extends State<FacturationDetailChargesSection> {
  /// Les natures dépliées, par `fee_code`.
  ///
  /// ⚠️ **Cet état vit AU-DESSUS du `BlocConsumer`, et c'est le piège du lot.**
  /// Cette section est relue en **silence** à chaque signal de
  /// `LedgerRevalidationCubit` et après chaque encaissement. Porté dans le
  /// `builder`, l'état se reconstruirait à chaque émission et replierait tout
  /// sous les doigts de l'opérateur, sans qu'il ait rien fait.
  ///
  /// Clé sur le `fee_code` et non sur l'index : le pli suit la nature, pas sa
  /// position — une créance qui disparaît ne doit pas déplier sa voisine.
  final Set<String> _expanded = <String>{};

  void _toggle(String feeCode) {
    setState(() {
      if (!_expanded.remove(feeCode)) _expanded.add(feeCode);
    });
  }

  void _retry(BuildContext context) {
    context.read<StudentChargesBloc>().add(
      StudentChargesByAcademicYearRequested(
        studentId: widget.studentId,
        academicYearId: widget.academicYearId,
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
              // Trois mailles : les natures, les tranches qu'elles portent,
              // et ce qu'il reste à encaisser.
              //
              // ⚠️ Le dernier compte vient du **reste composé**, jamais de
              // `charge.status` — que rien ne recalcule après un encaissement
              // local. Il annonçait « 2 à régler » au-dessus de deux lignes que
              // le guichet venait de solder (FRONT §6/§8).
              final natureCount = groupChargesByFeeCode(
                state.studentCharges,
              ).length;
              final unsettledCount = state.studentCharges
                  .where((charge) => charge.remainingInCents > 0)
                  .length;

              final subtitle = state.status == StudentChargesStatus.success
                  ? l10n.facturationDetailChargesSummary(
                      natureCount,
                      state.studentCharges.length,
                      unsettledCount,
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

                      final groups = groupChargesByFeeCode(
                        state.studentCharges,
                      );

                      return BlocBuilder<
                        FeeSectionTitlesCubit,
                        FeeSectionTitlesState
                      >(
                        buildWhen: (prev, curr) => prev.titles != curr.titles,
                        builder: (context, titles) => Column(
                          key: const ValueKey('charges-lines'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < groups.length; i++) ...[
                              FacturationChargeGroupAccordion(
                                key: ValueKey('group-${groups[i].feeCode}'),
                                group: groups[i],
                                schoolTitle: titles.titleOf(groups[i].feeCode),
                                expanded: _expanded.contains(groups[i].feeCode),
                                onToggle: () => _toggle(groups[i].feeCode),
                                onViewChargeRequested:
                                    widget.onViewChargeRequested,
                              ),
                              if (i < groups.length - 1)
                                const SizedBox(height: AppDimensions.spacingS),
                            ],
                          ],
                        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.facturationDetailChargesSectionTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
