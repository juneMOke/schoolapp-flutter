import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_context_pill.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau de marque de la page d'accueil (spec Accueil §01).
///
/// Surface Bleu Profond dégradée + filigrane kuba (unique usage du motif sur la
/// page) et liseré or en tête. Aucun appel réseau : la salutation vient de la
/// session ([AuthBloc]), le nom et la ville de l'école du référentiel local
/// ([SchoolIdentityCubit]), l'année scolaire du contexte académique déjà
/// résolu, la date de l'horloge du device.
class AccueilBrandBanner extends StatelessWidget {
  const AccueilBrandBanner({super.key});

  /// Lecture défensive du prénom : la page peut être montée sans [AuthBloc]
  /// au-dessus (tests de layout isolés) → salutation générique.
  String? _firstName(BuildContext context) {
    try {
      final firstName = context.read<AuthBloc>().state.user?.firstName.trim();
      return (firstName == null || firstName.isEmpty) ? null : firstName;
    } catch (_) {
      return null;
    }
  }

  /// Nom de l'année scolaire courante, ou `null` si le contexte académique
  /// n'est pas disponible (test isolé) — la pastille est alors simplement
  /// omise plutôt que d'afficher une année inventée.
  String? _academicYearName(BuildContext context) {
    try {
      final name = context
          .read<AcademicYearContextBloc>()
          .state
          .context
          ?.academicYear
          .name
          .trim();
      return (name == null || name.isEmpty) ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Eyebrow : « NOM DE L'ÉCOLE · VILLE » (spec §01). Lecture défensive comme
  /// les autres — sans identité résolue (référentiel pas encore pullé, test
  /// isolé), on retombe sur le nom de marque plutôt que sur un vide.
  String _eyebrow(BuildContext context, AppLocalizations l10n) {
    School? school;
    try {
      school = context.watch<SchoolIdentityCubit>().state.school;
    } catch (_) {
      school = null;
    }
    if (school == null) return l10n.schoolApp.toUpperCase();

    final locality = school.locality;
    final label = locality == null
        ? school.name
        : l10n.accueilBannerSchoolLocation(school.name, locality);
    return label.toUpperCase();
  }

  String _todayLabel(BuildContext context) {
    final longDate = MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime.now());
    return longDate.isEmpty
        ? longDate
        : '${longDate[0].toUpperCase()}${longDate.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = _firstName(context);
    final greeting = firstName == null
        ? l10n.accueilBannerGreetingGeneric
        : l10n.accueilBannerGreeting(firstName);
    final academicYear = _academicYearName(context);
    final eyebrow = _eyebrow(context, l10n);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AccueilUiTokens.bannerRadius),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                // 105° : le dégradé file vers la droite en descendant très
                // légèrement, comme la barre supérieure.
                gradient: LinearGradient(
                  begin: Alignment(-1, -0.26),
                  end: Alignment(1, 0.26),
                  colors: [
                    AppColors.bleuProfond,
                    AppColors.bleuArdoise,
                    AppColors.bleuArdoiseLight,
                  ],
                  stops: [0, 0.78, 1],
                ),
              ),
            ),
          ),
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AccueilUiTokens.bannerPaddingH,
              AccueilUiTokens.bannerPaddingTop,
              AccueilUiTokens.bannerPaddingH,
              AccueilUiTokens.bannerPaddingBottom,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    constraints.maxWidth < AccueilUiTokens.bannerStackThreshold;
                final text = _BannerText(
                  eyebrow: eyebrow,
                  greeting: greeting,
                  todayLabel: _todayLabel(context),
                  academicYearLabel: academicYear == null
                      ? null
                      : l10n.accueilBannerSchoolYear(academicYear),
                );
                const medallion = _BannerMedallion();

                // < 620 dp : le médaillon passe sous le texte (spec §01).
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text,
                      const SizedBox(
                        height: AccueilUiTokens.bannerTextMedaillonGap,
                      ),
                      medallion,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: text),
                    const SizedBox(
                      width: AccueilUiTokens.bannerTextMedaillonGap,
                    ),
                    medallion,
                  ],
                );
              },
            ),
          ),
          // Liseré or — signature discrète en tête du bandeau.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AccueilUiTokens.bannerAccentBarHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orDoux,
                    AppColors.orDoux.withValues(alpha: 0),
                  ],
                  stops: const [0, AccueilUiTokens.bannerAccentBarFadeStop],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerText extends StatelessWidget {
  final String eyebrow;
  final String greeting;
  final String todayLabel;
  final String? academicYearLabel;

  const _BannerText({
    required this.eyebrow,
    required this.greeting,
    required this.todayLabel,
    required this.academicYearLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow,
          style: AppTextStyles.badge.copyWith(
            color: AppColors.orDoux,
            letterSpacing: AccueilUiTokens.bannerEyebrowLetterSpacing,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AccueilUiTokens.bannerGreetingGapTop),
        Semantics(
          header: true,
          child: Text(
            greeting,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontWeight: FontWeight.w600,
              fontSize: AccueilUiTokens.bannerGreetingFontSize,
              height: AccueilUiTokens.bannerGreetingHeight,
              color: AppColors.blancCasse,
            ),
          ),
        ),
        const SizedBox(height: AccueilUiTokens.bannerGreetingGapBottom),
        Wrap(
          spacing: AccueilUiTokens.pillGap,
          runSpacing: AccueilUiTokens.pillGap,
          children: [
            AccueilContextPill(
              icon: Icons.calendar_today_outlined,
              label: todayLabel,
            ),
            if (academicYearLabel != null)
              AccueilContextPill(
                icon: Icons.school_outlined,
                label: academicYearLabel!,
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerMedallion extends StatelessWidget {
  const _BannerMedallion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AccueilUiTokens.bannerMedaillonSize,
      height: AccueilUiTokens.bannerMedaillonSize,
      decoration: BoxDecoration(
        color: AppColors.blancCasse.withValues(
          alpha: AccueilUiTokens.bannerMedaillonFillOpacity,
        ),
        borderRadius: BorderRadius.circular(
          AccueilUiTokens.bannerMedaillonRadius,
        ),
        border: Border.all(
          color: AppColors.blancCasse.withValues(
            alpha: AccueilUiTokens.bannerMedaillonBorderOpacity,
          ),
        ),
        // Halo : le médaillon se détache du dégradé sans bord dur.
        boxShadow: [
          BoxShadow(
            color: AppColors.blancCasse.withValues(
              alpha: AccueilUiTokens.bannerMedaillonHaloOpacity,
            ),
            spreadRadius: AccueilUiTokens.bannerMedaillonHaloWidth,
          ),
        ],
      ),
      child: const Center(
        child: EteeloLogo(
          variant: EteeloLogoVariant.symbolOnDark,
          size: AccueilUiTokens.bannerSymbolSize,
        ),
      ),
    );
  }
}
