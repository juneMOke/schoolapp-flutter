import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_dashboard_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Qui » — filles et garçons sur la fenêtre.
///
/// ## Pourquoi la note porte DEUX chiffres
///
/// La parité de la fenêtre seule se surinterprète : sur une journée à quatre
/// inscriptions, « 75 % de filles » ne dit rien de l'école. La note donne donc
/// aussi la parité de l'**effectif complet**, qui ne bouge pas avec la
/// fenêtre. Les deux sont comparables parce que le total de l'effectif EST la
/// somme de ses segments — même population, même dénominateur.
class EnrollmentGenderSection extends StatelessWidget {
  /// Répartition sur la fenêtre choisie.
  final GenderDistribution windowDistribution;

  /// Répartition de l'effectif complet, hors fenêtre.
  final GenderDistribution headcount;

  /// Vrai quand la fenêtre couvre une seule journée.
  final bool isSingleDay;

  /// Dossiers encore en cours sur la fenêtre.
  ///
  /// Ne sert **qu'à formuler le vide** : quand rien n'est finalisé, la carte
  /// dit combien de dossiers sont en cours plutôt que « aucune donnée ». Zéro
  /// par défaut — l'omettre dégrade la phrase, jamais le reste de la carte.
  final int inProgress;

  const EnrollmentGenderSection({
    super.key,
    required this.windowDistribution,
    required this.headcount,
    required this.isSingleDay,
    this.inProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segments = _segments(l10n, windowDistribution);

    final scope = isSingleDay
        ? l10n.enrollmentDashboardSubtitleDay
        : l10n.enrollmentDashboardSubtitlePeriod;

    // Rien de finalisé : la barre ne peut que dessiner sa piste, et une piste
    // grise muette se lit comme une panne d'affichage. Elle en a l'air
    // d'autant plus que la carte « Inscriptions » affiche, elle, un nombre —
    // c'est le profil NORMAL d'une semaine de rentrée, où les dossiers restent
    // en cours plusieurs jours. La carte dit donc ce qui est vrai : des
    // dossiers existent, aucun n'est encore finalisé.
    final splittable = segments.fold<int>(0, (sum, s) => sum + s.value.toInt());

    return EteeloStatsCard(
      title: l10n.enrollmentDashboardGenderTitle,
      icon: Icons.people_outline,
      // UNE seule mention de la fenêtre, portée par l'indice.
      //
      // La redline « Sous-titre : "du jour" si insOneDay » ne décrit pas un
      // second élément, elle décrit **la variation de cet indice**. Un
      // sous-titre « du jour » sous un indice « Sur les 14 inscrits du jour »
      // écrivait deux fois la même chose.
      //
      // L'indice dit sur combien de dossiers la barre répartit : « 50 % de
      // filles » sur quatre inscriptions ne se lit pas comme sur quatre cents.
      hint: l10n.enrollmentDashboardGenderHint(windowDistribution.total, scope),
      child: splittable == 0
          ? EnrollmentDashboardNote(text: nothingToSplitText(l10n, inProgress))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EteeloSplitBar(
                  segments: segments,
                  semanticsLabel: segments
                      .map((s) => '${s.label} : ${s.valueLabel}')
                      .join(', '),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                EnrollmentDashboardNote(
                  text: l10n.enrollmentDashboardGenderNote(
                    _girlsShare(windowDistribution),
                    _girlsShare(headcount),
                  ),
                ),
              ],
            ),
    );
  }

  /// Ce qu'on écrit quand il n'y a rien à répartir.
  ///
  /// **Jamais « aucune donnée »** : la donnée existe, elle n'est simplement
  /// pas encore finalisée. Nommer les dossiers en cours est ce qui distingue
  /// un écran qui attend d'un écran en panne.
  ///
  /// Partagée par les deux cartes « qui » — elles rencontrent le même vide,
  /// pour la même raison, et doivent le dire de la même façon.
  static String nothingToSplitText(AppLocalizations l10n, int inProgress) =>
      inProgress > 0
      ? l10n.enrollmentDashboardNothingToSplitInProgress(inProgress)
      : l10n.enrollmentDashboardNothingToSplit;

  List<EteeloSplitBarSegment> _segments(
    AppLocalizations l10n,
    GenderDistribution distribution,
  ) {
    // L'ordre est fixe — filles puis garçons — pour que la barre ne change pas
    // de sens d'une fenêtre à l'autre selon qui est majoritaire.
    const order = [
      GenderSegmentCode.female,
      GenderSegmentCode.male,
      GenderSegmentCode.other,
    ];

    final byCode = {for (final s in distribution.segments) s.code: s};

    // Filles et garçons sont TOUJOURS montrés, même à zéro — leur absence se
    // lirait comme une donnée manquante. « Autre » n'apparaît que si le
    // serveur le porte : une catégorie vide qu'aucune école n'utilise
    // encombrerait la légende de tout le monde.
    return [
      for (final code in order)
        if (code != GenderSegmentCode.other || byCode.containsKey(code))
          EteeloSplitBarSegment(
            label: _labelOf(l10n, code),
            valueLabel: l10n.enrollmentDashboardStudentsCount(
              byCode[code]?.value ?? 0,
            ),
            value: byCode[code]?.value ?? 0,
            color: _colorOf(code),
          ),
    ];
  }

  static String _labelOf(AppLocalizations l10n, GenderSegmentCode code) =>
      switch (code) {
        GenderSegmentCode.female => l10n.enrollmentDashboardGenderGirls,
        GenderSegmentCode.male => l10n.enrollmentDashboardGenderBoys,
        GenderSegmentCode.other => l10n.enrollmentDashboardGenderOther,
      };

  static Color _colorOf(GenderSegmentCode code) => switch (code) {
    GenderSegmentCode.female => AppColors.enrollmentStatsFemale,
    GenderSegmentCode.male => AppColors.enrollmentStatsMale,
    GenderSegmentCode.other => AppColors.enrollmentStatsInProgress,
  };

  static int _girlsShare(GenderDistribution distribution) {
    final girls = distribution.segments
        .where((s) => s.code == GenderSegmentCode.female)
        .fold<int>(0, (sum, s) => sum + s.value);
    return EnrollmentDashboardFormat.share(girls, distribution.total);
  }
}

/// « Qui » — premières inscriptions contre réinscriptions.
///
/// Les pré-inscriptions en sont **exclues** : une pré-inscription n'est pas une
/// inscription. Elle le deviendra à sa validation, et comptera ce jour-là.
class EnrollmentTypeSection extends StatelessWidget {
  final EnrollmentKpis kpis;
  final bool isSingleDay;

  const EnrollmentTypeSection({
    super.key,
    required this.kpis,
    required this.isSingleDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final segments = [
      EteeloSplitBarSegment(
        label: l10n.enrollmentDashboardTypeFirst,
        valueLabel: l10n.enrollmentDashboardStudentsCount(
          kpis.firstEnrollments.value,
        ),
        value: kpis.firstEnrollments.value,
        color: AppColors.enrollmentStatsFirst,
      ),
      EteeloSplitBarSegment(
        label: l10n.enrollmentDashboardTypeRe,
        valueLabel: l10n.enrollmentDashboardStudentsCount(
          kpis.reEnrollments.value,
        ),
        value: kpis.reEnrollments.value,
        color: AppColors.enrollmentStatsRe,
      ),
    ];

    return EteeloStatsCard(
      title: l10n.enrollmentDashboardTypeTitle,
      icon: Icons.category_outlined,
      subtitle: isSingleDay
          ? l10n.enrollmentDashboardSubtitleDay
          : l10n.enrollmentDashboardSubtitlePeriod,
      // Ce que la barre oppose, en toutes lettres : « première » et
      // « réinscription » ne disent pas d'eux-mêmes ce qui les sépare.
      hint: l10n.enrollmentDashboardTypeHint,
      child: kpis.firstEnrollments.value + kpis.reEnrollments.value == 0
          ? EnrollmentDashboardNote(
              text: EnrollmentGenderSection.nothingToSplitText(
                l10n,
                kpis.inProgress.value,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EteeloSplitBar(
                  segments: segments,
                  semanticsLabel: segments
                      .map((s) => '${s.label} : ${s.valueLabel}')
                      .join(', '),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                EnrollmentDashboardNote(text: l10n.enrollmentDashboardTypeNote),
              ],
            ),
    );
  }
}

/// Une note sous un bloc : ce qu'un graphique ne peut pas dire lui-même.
class EnrollmentDashboardNote extends StatelessWidget {
  final String text;

  const EnrollmentDashboardNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: AppDimensions.detailMiniIconSize,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
