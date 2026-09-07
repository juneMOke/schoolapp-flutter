import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_day_entries_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_day_entries_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_export_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Qui, exactement, a été inscrit ce jour-là.
///
/// ## Elle n'existe que sur une journée
///
/// Au-delà d'un jour, la carte est **masquée, pas paginée à l'infini** : une
/// liste nominative d'une année entière n'est pas une lecture de tableau de
/// bord, c'est un export. Le bloc parent ne construit ce sous-arbre que quand
/// la fenêtre couvre un seul jour.
///
/// ## Le sexe est toujours écrit
///
/// L'avatar garde sa **teinte d'identité** — déterministe, dérivée de
/// l'identifiant de l'élève, auditée AA — et ne porte aucune information. Le
/// sexe est écrit sous le nom, en toutes lettres. Colorer l'avatar par sexe
/// aurait fait porter la donnée par la seule couleur, et sorti le composant de
/// sa palette auditée, pour une information déjà lisible.
///
/// ## L'heure peut manquer, et c'est voulu
///
/// La colonne Heure vient de `createdAt` — l'instant de la saisie — alors que
/// tout le reste de l'écran s'aligne sur `enrollmentDate`, la date
/// administrative. Sur un dossier antidaté ou poussé le soir depuis un poste
/// hors ligne, les deux divergent et l'heure ne dit plus rien de la journée
/// affichée. Elle laisse alors un tiret : mieux vaut une case vide qu'une
/// heure fausse dans une colonne qui a l'autorité d'une colonne.
class EnrollmentDayEntriesSection extends StatelessWidget {
  /// Ouvre le dossier d'un élève.
  final void Function(DayEnrollmentEntry entry)? onEntryTap;

  /// Année scolaire et instant de lecture — le pied des exports les porte,
  /// pour qu'une feuille imprimée dise toujours de quoi elle parle.
  ///
  /// `null` retire le bouton PDF : sans année ni date, le document ne pourrait
  /// pas se légender, et une feuille nominative sans périmètre est pire
  /// qu'absente.
  final String? schoolYear;
  final DateTime? generatedAt;

  const EnrollmentDayEntriesSection({
    super.key,
    this.onEntryTap,
    this.schoolYear,
    this.generatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
      builder: (context, state) {
        // Rien à montrer et rien à dire : la carte ne se rend pas du tout.
        // C'est le cas ordinaire d'une journée sans inscription — le vide de
        // l'écran entier a déjà été traité plus haut.
        if (state.status == EnrollmentDayEntriesStatus.initial ||
            state.status == EnrollmentDayEntriesStatus.empty) {
          return const SizedBox.shrink();
        }

        return EteeloStatsCard(
          title: l10n.enrollmentDashboardDayListTitle,
          subtitle: state.day == null
              ? null
              : l10n.enrollmentDashboardDayListSubtitle(
                  MaterialLocalizations.of(context).formatFullDate(state.day!),
                ),
          // Pas d'export sur une carte en erreur : il n'y a rien à copier.
          actions:
              state.status == EnrollmentDayEntriesStatus.success &&
                  state.day != null
              ? [
                  if (schoolYear != null && generatedAt != null)
                    EnrollmentExportActions.dayEntriesPdf(
                      context: context,
                      entries: state.entries,
                      day: state.day!,
                      schoolYear: schoolYear!,
                      generatedAt: generatedAt!,
                    ),
                  EnrollmentExportActions.dayEntriesCsv(
                    context: context,
                    entries: state.entries,
                    day: state.day!,
                  ),
                ]
              : const [],
          child: _body(context, l10n, state),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    EnrollmentDayEntriesState state,
  ) {
    // ⚠️ L'erreur de CETTE liste n'est pas l'erreur de la page.
    //
    // Le cas qui l'impose : un utilisateur qui détient le pilotage mais pas la
    // lecture des dossiers reçoit 200 sur l'agrégat et 403 ici. L'en-tête, le
    // bandeau, les onglets et les chiffres viennent d'un appel qui a réussi et
    // restent donc à l'écran ; seule la carte dit ce qui lui manque.
    if (state.status == EnrollmentDayEntriesStatus.error) {
      return _InlineMessage(
        icon: _isForbidden(state.failure)
            ? Icons.gpp_bad_rounded
            : Icons.error_outline_rounded,
        text: _isForbidden(state.failure)
            ? l10n.enrollmentDashboardDayListForbidden
            : l10n.enrollmentDashboardDayListError,
      );
    }

    final rows = [
      for (final entry in state.entries) _rowOf(context, l10n, entry),
    ];

    return DataTableView(
      rows: rows,
      config: DataTableViewConfig(
        isLoading: state.status == EnrollmentDayEntriesStatus.loading,
        loadingLabel: l10n.enrollmentDashboardDayListLoading,
        emptyLabel: l10n.enrollmentDashboardDayListEmpty,
        semanticsLabel: l10n.enrollmentDashboardDayListTitle,
        density: DataTableDensity.compact,
        columns: [
          DataTableColumnDef(
            label: l10n.enrollmentDashboardDayListColumnHour,
            flex: 8,
          ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardDayListColumnStudent,
            flex: 22,
          ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardDayListColumnLevel,
            flex: 13,
          ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardDayListColumnType,
            flex: 13,
          ),
          DataTableColumnDef(
            label: l10n.enrollmentDashboardDayListColumnRecordedBy,
            flex: 12,
          ),
        ],
        footer: DataTableFooterConfig(
          label: l10n.enrollmentDashboardDayListCount(state.totalElements),
          total: state.totalElements,
          unit: l10n.enrollmentDashboardDayListUnit,
          pagination: state.totalPages <= 1
              ? null
              : DataTablePaginationConfig(
                  // Le serveur compte les pages à partir de 0, la barre du
                  // socle à partir de 1.
                  currentPage: state.page + 1,
                  totalPages: state.totalPages,
                  pageSize: GetEnrollmentDayEntriesUseCase.pageSize,
                  isLoading: state.status == EnrollmentDayEntriesStatus.loading,
                  onPrevious: () => context
                      .read<EnrollmentDayEntriesBloc>()
                      .add(EnrollmentDayEntriesPageChanged(state.page - 1)),
                  onNext: () => context.read<EnrollmentDayEntriesBloc>().add(
                    EnrollmentDayEntriesPageChanged(state.page + 1),
                  ),
                ),
        ),
      ),
    );
  }

  DataTableRowSpec _rowOf(
    BuildContext context,
    AppLocalizations l10n,
    DayEnrollmentEntry entry,
  ) {
    final genderLabel = entry.gender == Gender.female
        ? l10n.enrollmentDashboardGenderGirls
        : l10n.enrollmentDashboardGenderBoys;
    final typeLabel = entry.formerStudent
        ? l10n.enrollmentDashboardTypeRe
        : l10n.enrollmentDashboardTypeFirst;

    return DataTableRowSpec(
      id: entry.enrollmentId,
      displayName: entry.displayName,
      leading: StudentAvatar(
        firstName: entry.firstName,
        lastName: entry.lastName,
        studentId: entry.studentId,
        size: AppDimensions.enrollmentDashboardDayAvatarSize,
      ),
      onTap: onEntryTap == null ? null : () => onEntryTap!(entry),
      cells: [
        DataTableCellSpec(
          text: entry.hourIsMeaningful
              ? MaterialLocalizations.of(
                  context,
                ).formatTimeOfDay(TimeOfDay.fromDateTime(entry.createdAt))
              : l10n.enrollmentDashboardDayListNoHour,
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          text: entry.displayName,
          variant: DataTableCellTextVariant.strong,
          // Le sexe, écrit. Jamais porté par la seule couleur de l'avatar.
          secondaryText: genderLabel,
        ),
        DataTableCellSpec(text: entry.schoolLevel),
        DataTableCellSpec(
          child: _TypePill(label: typeLabel, isReturning: entry.formerStudent),
        ),
        DataTableCellSpec(
          // Nul quand l'annuaire ne résout pas — compte inconnu, ou écriture
          // SYSTEM. Un tiret, jamais une attribution inventée.
          text: entry.recordedBy?.trim().isNotEmpty == true
              ? entry.recordedBy!
              : l10n.enrollmentDashboardDayListUnknownAgent,
        ),
      ],
    );
  }

  /// 403 sur la liste alors que l'agrégat a répondu : droit manquant, pas panne.
  static bool _isForbidden(Failure? failure) => failure is UnauthorizedFailure;
}

/// Pastille de type — fond doux, texte accentué, bord léger.
class _TypePill extends StatelessWidget {
  final String label;
  final bool isReturning;

  const _TypePill({required this.label, required this.isReturning});

  @override
  Widget build(BuildContext context) {
    final color = isReturning
        ? AppColors.enrollmentStatsRe
        : AppColors.enrollmentStatsFirst;
    final soft = isReturning
        ? AppColors.enrollmentStatsReSoft
        : AppColors.enrollmentStatsFirstSoft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.chipPaddingH,
        vertical: AppDimensions.chipPaddingV,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentDashboardPillRadius,
        ),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReturning ? Icons.refresh_rounded : Icons.person_add_rounded,
            size: AppDimensions.enrollmentDashboardTypePillIconSize,
            color: color,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.badge.copyWith(color: color),
            ),
          ),
        ],
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
