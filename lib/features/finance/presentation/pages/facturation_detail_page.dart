import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_data_loader.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_payments_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationDetailPage extends StatelessWidget {
  final FacturationDetailIntent intent;

  const FacturationDetailPage({super.key, required this.intent});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutesNames.facturations);
  }

  void _showPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pageUnderConstruction)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentsBloc>(create: (_) => getIt<PaymentsBloc>()),
        BlocProvider<StudentChargesBloc>(
          create: (_) => getIt<StudentChargesBloc>(),
        ),
      ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.financeDetailAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.sectionCardRadius,
                            ),
                          ),
                        ),
                        onPressed: () => _goBack(context),
                        icon: const Icon(Icons.arrow_back_outlined),
                        label: Text(
                          l10n.facturationDetailBackLabel,
                          style: AppTextStyles.action,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      _DetailHero(intent: intent),
                      const SizedBox(height: AppDimensions.detailSectionSpacing),
                      if (!intent.hasDisplayContext)
                        _ContextErrorCard(
                          title: l10n.facturationDetailContextErrorTitle,
                          message: l10n.facturationDetailContextErrorMessage,
                        )
                      else
                        FacturationDetailDataLoader(
                          intent: intent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FacturationDetailPaymentsSection(
                                studentId: intent.studentId,
                                academicYearId: intent.academicYearId,
                                onCreatePaymentRequested: () =>
                                    _showPlaceholder(context),
                                onViewPaymentRequested: (Payment _) =>
                                    _showPlaceholder(context),
                              ),
                              const SizedBox(
                                height: AppDimensions.detailSectionSpacing,
                              ),
                              FacturationDetailChargesSection(
                                studentId: intent.studentId,
                                academicYearId: intent.academicYearId,
                                onViewChargeRequested: (StudentCharge _) =>
                                    _showPlaceholder(context),
                              ),
                            ],
                          ),
                        ),
                    ],
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

class _DetailHero extends StatelessWidget {
  final FacturationDetailIntent intent;

  const _DetailHero({required this.intent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = [intent.lastName, intent.firstName, intent.surname]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.financeDetailInfoSurface,
            AppColors.financeDetailCard,
          ],
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxWidth < AppDimensions.detailCompactBreakpoint;

          final metaBadges = Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              if (intent.levelGroupName.trim().isNotEmpty)
                _MetaBadge(
                  label: l10n.facturationDetailStudentLevelGroup,
                  value: intent.levelGroupName,
                  accent: AppColors.financeDetailAmber,
                  accentSoft: AppColors.financeDetailAmberSoft,
                ),
              if (intent.levelName.trim().isNotEmpty)
                _MetaBadge(
                  label: l10n.facturationDetailStudentLevel,
                  value: intent.levelName,
                  accent: AppColors.financeDetailTeal,
                  accentSoft: AppColors.financeDetailTealSoft,
                ),
            ],
          );

          final featureChips = Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              _FeatureChip(
                label: l10n.facturationDetailInfoChipPayments,
                icon: Icons.payments_outlined,
                accent: AppColors.financeDetailPaymentsAccent,
                accentSoft: AppColors.financeDetailPaymentsAccentSoft,
              ),
              _FeatureChip(
                label: l10n.facturationDetailInfoChipCharges,
                icon: Icons.receipt_long_outlined,
                accent: AppColors.financeDetailChargesAccent,
                accentSoft: AppColors.financeDetailChargesAccentSoft,
              ),
            ],
          );

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.facturationDetailInfoTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                fullName.isEmpty
                    ? l10n.facturationDetailUnknownValue
                    : fullName,
                style: AppTextStyles.detailHeroTitle.copyWith(
                  color: AppColors.financeDetailAccent,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              metaBadges,
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.facturationDetailInfoSubtitle,
                style: AppTextStyles.detailHeroSubtitle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              featureChips,
            ],
          );

          final avatar = Container(
            width: AppDimensions.detailHeroAvatarSize,
            height: AppDimensions.detailHeroAvatarSize,
            decoration: BoxDecoration(
              color: AppColors.financeDetailAccentSoft,
              borderRadius: BorderRadius.circular(AppDimensions.spacingXL),
              border: Border.all(
                color: AppColors.financeDetailAccent.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: AppDimensions.detailHeaderIconSize,
              color: AppColors.financeDetailAccent,
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(height: AppDimensions.spacingM),
                textContent,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: textContent),
            ],
          );
        },
      ),
    );
  }
}

/// Badge compact affichant un label et sa valeur (ex: Cycle · Secondaire).
class _MetaBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Color accentSoft;

  const _MetaBadge({
    required this.label,
    required this.value,
    required this.accent,
    required this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingL),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label · ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.caption.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip feature affichant une icône et un libellé (ex: Paiements, Charges).
class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Color accentSoft;

  const _FeatureChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingL),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: accent),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}