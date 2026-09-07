import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cinq fenêtres de temps, et ce qu'elles couvrent.
///
/// Des onglets **pleins** de 44 dp, pas un filtre secondaire : « le choix de la
/// période est l'action la plus fréquente de l'écran, il ne doit jamais être
/// confondu avec un filtre secondaire ». Ils s'enroulent sur deux rangs plutôt
/// que de se comprimer, pour que la cible tactile tienne sur tablette étroite.
///
/// Sous les onglets, **le libellé de la plage comptée** — ou, pour la fenêtre
/// libre, les deux champs qui la définissent.
class EnrollmentDashboardWindowTabs extends StatelessWidget {
  const EnrollmentDashboardWindowTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EnrollmentStatsBloc, EnrollmentStatsState>(
      buildWhen: (prev, curr) =>
          prev.window != curr.window ||
          prev.stats?.context.schoolYear != curr.stats?.context.schoolYear,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedTabFilter<EnrollmentStatsWindowKind>(
              semanticsLabel: l10n.enrollmentDashboardWindowTabsA11yLabel,
              style: SegmentedTabFilterStyle.window,
              wrap: true,
              selected: state.window.kind,
              onSelected: (kind) => _onSelected(context, state, kind),
              options: [
                _option(
                  l10n.enrollmentDashboardWindowDay,
                  EnrollmentStatsWindowKind.day,
                  Icons.schedule_outlined,
                ),
                _option(
                  l10n.enrollmentDashboardWindowWeek,
                  EnrollmentStatsWindowKind.week,
                  Icons.calendar_today_outlined,
                ),
                _option(
                  l10n.enrollmentDashboardWindowMonth,
                  EnrollmentStatsWindowKind.month,
                  Icons.event_note_outlined,
                ),
                _option(
                  l10n.enrollmentDashboardWindowYear,
                  EnrollmentStatsWindowKind.year,
                  Icons.history_outlined,
                ),
                _option(
                  l10n.enrollmentDashboardWindowCustom,
                  EnrollmentStatsWindowKind.custom,
                  Icons.filter_alt_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            if (state.window.kind == EnrollmentStatsWindowKind.custom)
              _CustomRangeFields(window: state.window)
            else
              _RangeLabel(
                window: state.window,
                schoolYear: state.stats?.context.schoolYear,
              ),
          ],
        );
      },
    );
  }

  /// Un onglet, son libellé et **son glyphe**.
  ///
  /// Les cinq glyphes sont ceux de la spec, et ils sont volontairement de
  /// familles différentes : horloge, calendrier nu, calendrier réglé,
  /// historique, entonnoir. La version précédente prenait cinq variantes de
  /// calendrier (`today`, `view_week`, `calendar_month`, `event_note`,
  /// `date_range`) — présentes, mais indistinguables à 16 dp, ce qui revenait
  /// à n'en avoir aucune.
  SegmentedTabOption<EnrollmentStatsWindowKind> _option(
    String label,
    EnrollmentStatsWindowKind value,
    IconData icon,
  ) => SegmentedTabOption(label: label, value: value, icon: icon);

  /// Passer d'un onglet à l'autre **relance la lecture**.
  ///
  /// La fenêtre libre est le seul onglet qui ne demande rien en arrivant : tant
  /// que ses deux bornes ne sont pas posées, il n'y a pas de fenêtre à compter,
  /// et le serveur refuserait en 400 — à raison.
  void _onSelected(
    BuildContext context,
    EnrollmentStatsState state,
    EnrollmentStatsWindowKind kind,
  ) {
    if (kind == state.window.kind) return;

    final today = DateTime.now();
    final window = switch (kind) {
      EnrollmentStatsWindowKind.day => EnrollmentStatsWindow.day(today),
      EnrollmentStatsWindowKind.week => const EnrollmentStatsWindow.week(),
      EnrollmentStatsWindowKind.month => const EnrollmentStatsWindow.month(),
      EnrollmentStatsWindowKind.year => const EnrollmentStatsWindow.year(),
      // Par défaut, la journée d'aujourd'hui : une fenêtre valide et lisible,
      // que l'utilisateur élargit ensuite. Ouvrir sur deux champs vides
      // laisserait l'écran sans chiffres sans dire pourquoi.
      EnrollmentStatsWindowKind.custom => EnrollmentStatsWindow.custom(
        from: today,
        to: today,
      ),
    };

    context.read<EnrollmentStatsBloc>().add(
      EnrollmentStatsRequested(window: window),
    );
  }
}

/// Ce que la fenêtre courante couvre, en toutes lettres.
///
/// ## Pourquoi ce libellé ne vient PAS du serveur
///
/// `context.periodStart`/`periodEnd` décrivent **l'axe tracé**, pas la fenêtre
/// comptée : sur l'onglet « Aujourd'hui », l'axe fait cinq jours (« un seul
/// jour ne se lit pas seul ») alors que les chiffres clés comptent une seule
/// journée. Les afficher ici légenderait « 1er au 5 septembre » au-dessus du
/// total du 5.
///
/// La fenêtre comptée, elle, se connaît sans le serveur — sauf pour l'année.
class _RangeLabel extends StatelessWidget {
  final EnrollmentStatsWindow window;
  final String? schoolYear;

  const _RangeLabel({required this.window, required this.schoolYear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final today = DateTime.now();

    final text = switch (window.kind) {
      // Une journée : elle se nomme entièrement.
      EnrollmentStatsWindowKind.day => materialL10n.formatFullDate(
        window.day ?? today,
      ),
      // Lundi de la semaine courante. Par soustraction sur le quantième plutôt
      // qu'avec une `Duration` : `DateTime` normalise un jour négatif en
      // remontant le mois, et le dépôt réserve `Duration` aux tokens de
      // mouvement (garde-fou de pré-commit).
      EnrollmentStatsWindowKind.week => l10n.enrollmentDashboardRangeFromTo(
        materialL10n.formatFullDate(
          DateTime(
            today.year,
            today.month,
            today.day - (today.weekday - DateTime.monday),
          ),
        ),
        materialL10n.formatFullDate(today),
      ),
      // Depuis le 1er, jusqu'à aujourd'hui.
      EnrollmentStatsWindowKind.month => l10n.enrollmentDashboardRangeFromTo(
        materialL10n.formatFullDate(DateTime(today.year, today.month)),
        materialL10n.formatFullDate(today),
      ),
      // L'année scolaire NE COMMENCE PAS à une date que le client connaisse :
      // elle part de l'ouverture des inscriptions, un fait serveur, et un
      // dossier antidaté peut même la faire commencer avant. On nomme donc
      // l'année plutôt que d'inventer deux bornes.
      EnrollmentStatsWindowKind.year =>
        schoolYear == null
            ? l10n.enrollmentDashboardRangeSinceOpening
            : l10n.enrollmentDashboardRangeSchoolYear(schoolYear!),
      // Remplacé par les deux champs de saisie.
      EnrollmentStatsWindowKind.custom => '',
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return Text(
      text,
      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    );
  }
}

/// Les deux bornes d'une fenêtre libre.
///
/// Les bornes sont **contraintes l'une par l'autre** : « Du » ne peut pas
/// dépasser « Au », et réciproquement. Le serveur refuse les bornes inversées
/// en 400 sans les échanger — et il a raison, une plage à l'envers trahit un
/// calcul faux. Mais l'utilisateur n'a pas à découvrir cette règle par une
/// erreur : le sélecteur ne la lui laisse pas composer.
class _CustomRangeFields extends StatelessWidget {
  final EnrollmentStatsWindow window;

  const _CustomRangeFields({required this.window});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final from = window.from;
    final to = window.to;

    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingS,
      children: [
        SizedBox(
          width: AppDimensions.enrollmentDashboardDateFieldWidth,
          child: EteeloDateInput(
            label: l10n.enrollmentDashboardRangeFieldFrom,
            value: from,
            lastDate: to,
            onChanged: (value) => _request(context, from: value, to: to),
          ),
        ),
        SizedBox(
          width: AppDimensions.enrollmentDashboardDateFieldWidth,
          child: EteeloDateInput(
            label: l10n.enrollmentDashboardRangeFieldTo,
            value: to,
            firstDate: from,
            onChanged: (value) => _request(context, from: from, to: value),
          ),
        ),
      ],
    );
  }

  /// Ne demande que lorsque la fenêtre est complète.
  ///
  /// Une borne effacée ne déclenche rien : `custom` sans ses deux bornes est
  /// un 400, et le serveur refuse **exprès** de se replier sur l'année plutôt
  /// que d'afficher des chiffres exacts sous une légende fausse.
  void _request(
    BuildContext context, {
    required DateTime? from,
    required DateTime? to,
  }) {
    if (from == null || to == null || from.isAfter(to)) return;

    context.read<EnrollmentStatsBloc>().add(
      EnrollmentStatsRequested(
        window: EnrollmentStatsWindow.custom(from: from, to: to),
      ),
    );
  }
}
