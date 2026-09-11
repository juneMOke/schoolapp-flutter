import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_entries_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_entries_report_button.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_entry_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Qui, exactement, a été inscrit sur la fenêtre choisie.
///
/// ## Toutes les fenêtres, page par page
///
/// La carte suit le sélecteur — un jour, une semaine, un mois, l'année ou une
/// période libre — et pagine à huit lignes quelle que soit la largeur de la
/// fenêtre : le serveur refuse les grandes pages, parce que ce qui protège une
/// liste de noms est la taille de page, pas l'étroitesse de la fenêtre.
/// L'exhaustif s'emporte en PDF, composé par le serveur sur la même fenêtre et
/// dans le même ordre.
///
/// ## L'heure sur un jour, la date au-delà
///
/// Sur une journée, la date est dans le sous-titre et la colonne dit l'heure.
/// Au-delà, l'heure seule ne situerait plus la ligne : la colonne passe à la
/// date administrative, `enrollmentDate` — l'horloge de tout l'écran. Le
/// contenu des lignes vit dans [EnrollmentEntryRow].
class EnrollmentEntriesSection extends StatelessWidget {
  /// Ouvre le dossier d'un élève.
  final void Function(DayEnrollmentEntry entry)? onEntryTap;

  /// L'année scolaire, pour nommer la fenêtre « année ». `null` : « depuis
  /// l'ouverture des inscriptions ».
  final String? schoolYear;

  const EnrollmentEntriesSection({super.key, this.onEntryTap, this.schoolYear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EnrollmentEntriesBloc, EnrollmentEntriesState>(
      builder: (context, state) {
        // Rien à montrer et rien à dire : la carte ne se rend pas du tout.
        // C'est le cas ordinaire d'une fenêtre sans inscription terminée — le
        // vide de l'écran entier a déjà été traité plus haut.
        if (state.status == EnrollmentEntriesStatus.initial ||
            state.status == EnrollmentEntriesStatus.empty) {
          return const SizedBox.shrink();
        }

        final window = state.window;
        return EteeloStatsCard(
          title: l10n.enrollmentDashboardEntriesTitle,
          subtitle: window == null ? null : _subtitleOf(context, l10n, window),
          // Le PDF s'offre dès que la fenêtre a des lignes, et reste en place
          // pendant qu'une autre page charge : le document ne dépend pas de la
          // page affichée. Pas en erreur — il n'y aurait rien qu'on ait lu.
          actions:
              window != null &&
                  state.totalElements > 0 &&
                  state.status != EnrollmentEntriesStatus.error
              ? [EnrollmentEntriesReportButton(window: window)]
              : const [],
          child: _body(context, l10n, state),
        );
      },
    );
  }

  /// La journée en toutes lettres, la semaine ou le mois courants, l'année
  /// scolaire, ou les deux bornes d'une période libre.
  ///
  /// ⚠️ **L'année se nomme, elle ne se borne pas** : la liste s'y cadre par
  /// année scolaire et non par dates — un dossier antidaté en fait partie.
  /// Deux bornes annonceraient un périmètre qu'elle ne respecte pas.
  String _subtitleOf(
    BuildContext context,
    AppLocalizations l10n,
    EnrollmentStatsWindow window,
  ) {
    final dates = MaterialLocalizations.of(context);
    return switch (window.kind) {
      EnrollmentStatsWindowKind.day =>
        l10n.enrollmentDashboardEntriesSubtitleDay(
          dates.formatFullDate(window.day!),
        ),
      EnrollmentStatsWindowKind.custom when window.isSingleDay =>
        l10n.enrollmentDashboardEntriesSubtitleDay(
          dates.formatFullDate(window.from!),
        ),
      EnrollmentStatsWindowKind.custom =>
        l10n.enrollmentDashboardEntriesSubtitleRange(
          dates.formatMediumDate(window.from!),
          dates.formatMediumDate(window.to!),
        ),
      EnrollmentStatsWindowKind.week =>
        l10n.enrollmentDashboardEntriesSubtitleWeek,
      EnrollmentStatsWindowKind.month =>
        l10n.enrollmentDashboardEntriesSubtitleMonth,
      EnrollmentStatsWindowKind.year =>
        schoolYear == null
            ? l10n.enrollmentDashboardEntriesSubtitleSinceOpening
            : l10n.enrollmentDashboardEntriesSubtitleYear(schoolYear!),
    };
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    EnrollmentEntriesState state,
  ) {
    // ⚠️ L'erreur de CETTE liste n'est pas l'erreur de la page.
    //
    // Le cas qui l'impose : un utilisateur qui détient le pilotage mais pas la
    // lecture des dossiers reçoit 200 sur l'agrégat et 403 ici. L'en-tête, le
    // bandeau, les onglets et les chiffres viennent d'un appel qui a réussi et
    // restent donc à l'écran ; seule la carte dit ce qui lui manque.
    if (state.status == EnrollmentEntriesStatus.error) {
      final forbidden = state.failure is UnauthorizedFailure;
      return _InlineMessage(
        icon: forbidden ? Icons.gpp_bad_rounded : Icons.error_outline_rounded,
        text: forbidden
            ? l10n.enrollmentDashboardEntriesForbidden
            : l10n.enrollmentDashboardEntriesError,
      );
    }

    // Hors de l'état initial, la liste connaît toujours sa fenêtre.
    final singleDay = state.window?.isSingleDay ?? true;

    return DataTableView(
      rows: [
        for (final entry in state.entries)
          EnrollmentEntryRow.of(
            context,
            entry,
            singleDay: singleDay,
            onTap: onEntryTap,
          ),
      ],
      config: DataTableViewConfig(
        isLoading: state.status == EnrollmentEntriesStatus.loading,
        loadingLabel: l10n.enrollmentDashboardEntriesLoading,
        emptyLabel: l10n.enrollmentDashboardEntriesEmpty,
        semanticsLabel: l10n.enrollmentDashboardEntriesTitle,
        density: DataTableDensity.compact,
        columns: [
          // Une date tient plus large qu'une heure.
          singleDay
              ? DataTableColumnDef(
                  label: l10n.enrollmentDashboardEntriesColumnHour,
                  flex: 8,
                )
              : DataTableColumnDef(
                  label: l10n.enrollmentDashboardEntriesColumnDate,
                  flex: 10,
                ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardEntriesColumnStudent,
            flex: 22,
          ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardEntriesColumnLevel,
            flex: 13,
          ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardEntriesColumnType,
            flex: 13,
          ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardEntriesColumnRecordedBy,
            flex: 12,
          ),
        ],
        footer: DataTableFooterConfig(
          label: l10n.enrollmentDashboardEntriesCount(state.totalElements),
          total: state.totalElements,
          unit: l10n.enrollmentDashboardEntriesUnit,
          pagination: state.totalPages <= 1
              ? null
              : DataTablePaginationConfig(
                  // Le serveur compte les pages à partir de 0, la barre du
                  // socle à partir de 1.
                  currentPage: state.page + 1,
                  totalPages: state.totalPages,
                  pageSize: GetEnrollmentEntriesUseCase.pageSize,
                  isLoading: state.status == EnrollmentEntriesStatus.loading,
                  onPrevious: () => context.read<EnrollmentEntriesBloc>().add(
                    EnrollmentEntriesPageChanged(state.page - 1),
                  ),
                  onNext: () => context.read<EnrollmentEntriesBloc>().add(
                    EnrollmentEntriesPageChanged(state.page + 1),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Un message dans la carte, à la place du tableau.
class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppDimensions.detailMiniIconSize,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
