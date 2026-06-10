import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau de marque de la page d'accueil (spec Accueil §01).
///
/// Surface Bleu Profond dégradée + filigrane kuba (unique usage du motif sur la
/// page). Statique : aucune donnée serveur. La salutation utilise le prénom de
/// la session ([AuthBloc]) ; la ligne de contexte affiche la date longue
/// localisée du jour.
///
/// L'eyebrow réutilise le nom de marque en attendant le profil d'établissement
/// (le nom d'école / la ville viendront de ce profil — cf. spec §00 Tweaks).
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

  String _contextLine(BuildContext context, AppLocalizations l10n) {
    final today = DateTime.now();
    final longDate = MaterialLocalizations.of(context).formatFullDate(today);
    final capitalized = longDate.isEmpty
        ? longDate
        : '${longDate[0].toUpperCase()}${longDate.substring(1)}';
    return '$capitalized · ${l10n.accueilBannerContextTail}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = _firstName(context);
    final greeting = firstName == null
        ? l10n.accueilBannerGreetingGeneric
        : l10n.accueilBannerGreeting(firstName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AccueilUiTokens.bannerRadius),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
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
                  greeting: greeting,
                  contextLine: _contextLine(context, l10n),
                  eyebrow: l10n.schoolApp.toUpperCase(),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }
}

class _BannerText extends StatelessWidget {
  final String eyebrow;
  final String greeting;
  final String contextLine;

  const _BannerText({
    required this.eyebrow,
    required this.greeting,
    required this.contextLine,
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
        Text(
          contextLine,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: AccueilUiTokens.bannerContextHeight,
            color: AppColors.blancCasse.withValues(
              alpha: AccueilUiTokens.bannerContextOpacity,
            ),
          ),
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
