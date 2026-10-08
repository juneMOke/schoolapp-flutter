import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/components/status/sync_state_icon.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_row_selection.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_data_table_sorter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_listing_tones.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_suspension_marks.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentDataTable extends StatefulWidget {
  final List<EnrollmentSummary> enrollments;
  final int? totalCount;
  final ValueChanged<EnrollmentSummary> onViewRequested;
  final bool isLoading;
  final bool isError;
  final String? loadingLabel;
  final String? errorLabel;
  final String? emptyLabel;
  final int currentPage;
  final int totalPages;
  final DataTableDensity density;
  final bool showPagination;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final String Function(int current, int total)? pageLabelBuilder;
  final int pageSize;

  const EnrollmentDataTable({
    super.key,
    required this.enrollments,
    required this.onViewRequested,
    this.totalCount,
    this.isLoading = false,
    this.isError = false,
    this.loadingLabel,
    this.errorLabel,
    this.emptyLabel,
    this.currentPage = 1,
    this.totalPages = 1,
    this.density = DataTableDensity.comfortable,
    this.showPagination = true,
    this.onPreviousPage,
    this.onNextPage,
    this.pageLabelBuilder,
    this.pageSize = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  State<EnrollmentDataTable> createState() => _EnrollmentDataTableState();
}

class _EnrollmentDataTableState extends State<EnrollmentDataTable> {
  EnrollmentSortColumn _sortColumn = EnrollmentSortColumn.student;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = EnrollmentDataTableSorter.sort(
      widget.enrollments,
      _sortColumn,
      _sortAscending,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Rendu étroit (téléphone) : la colonne Date fusionne en sous-texte du
        // nom → 2 colonnes (Élève | Statut) au lieu de 3, pour rester lisible.
        final isCompact =
            constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        return _buildTable(l10n, sorted, isCompact);
      },
    );
  }

  Widget _buildTable(
    AppLocalizations l10n,
    List<EnrollmentSummary> sorted,
    bool isCompact,
  ) {
    final selection = EnrollmentRowSelectionScope.of(context);
    return DataTableView(
      rows: _buildRows(sorted, l10n, isCompact, selection),
      config: DataTableViewConfig(
        columns: [
          // La case du mode sélection : une colonne en tête, étroite.
          if (selection != null) const DataTableColumnDef(label: '', flex: 1),
          ..._buildColumns(l10n, isCompact),
        ],
        isLoading: widget.isLoading,
        isError: widget.isError,
        loadingLabel: widget.loadingLabel ?? l10n.loadingStudents,
        errorLabel: widget.errorLabel ?? l10n.noResultsFound,
        sortColumnIndex: _sortColumn.index,
        sortAscending: _sortAscending,
        onSortChanged: _onSortChanged,
        emptyLabel: widget.emptyLabel ?? l10n.enrollmentNoResultsDescription,
        footer: DataTableFooterConfig(
          label: l10n.paginationResultsCount(sorted.length),
          total: widget.totalCount,
          unit: l10n.unitStudents,
          pagination: _buildPaginationConfig(),
        ),
        density: widget.density,
        semanticsLabel: l10n.enrollmentResultsA11yLabel,
        // La table appartient au temps du RÉSULTAT : elle porte donc la terre
        // cuite, comme la barre au-dessus d'elle. C'est la seule table teintée
        // de l'application — toutes les autres gardent le rendu blanc.
        tone: EnrollmentListingTones.table,
      ),
    );
  }

  DataTablePaginationConfig? _buildPaginationConfig() {
    if (!widget.showPagination || widget.totalPages <= 1) {
      return null;
    }
    if (widget.onPreviousPage == null || widget.onNextPage == null) {
      return null;
    }

    return DataTablePaginationConfig(
      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      pageSize: widget.pageSize,
      onPrevious: widget.onPreviousPage!,
      onNext: widget.onNextPage!,
      isLoading: widget.isLoading,
      pageLabel: widget.pageLabelBuilder,
    );
  }

  List<DataTableColumnDef> _buildColumns(
    AppLocalizations l10n,
    bool isCompact,
  ) {
    if (isCompact) {
      return [
        DataTableColumnDef(
          label: l10n.enrollmentStudentColumnLabel,
          flex: 3,
          sortable: true,
          sortIndex: EnrollmentSortColumn.student.index,
        ),
        DataTableColumnDef(label: l10n.enrollmentStatusFilterLabel, flex: 2),
      ];
    }

    return [
      DataTableColumnDef(
        label: l10n.enrollmentStudentColumnLabel,
        flex: 7,
        sortable: true,
        sortIndex: EnrollmentSortColumn.student.index,
      ),
      DataTableColumnDef(
        label: l10n.dateOfBirth,
        flex: 2,
        sortable: true,
        sortIndex: EnrollmentSortColumn.dateOfBirth.index,
      ),
      DataTableColumnDef(label: l10n.enrollmentStatusFilterLabel, flex: 2),
    ];
  }

  List<DataTableRowSpec> _buildRows(
    List<EnrollmentSummary> enrollments,
    AppLocalizations l10n,
    bool isCompact,
    EnrollmentRowSelection? selection,
  ) {
    return enrollments
        .map(
          (enrollment) => DataTableRowSpec(
            id: enrollment.enrollmentId,
            displayName: _studentFullName(enrollment),
            // En mode sélection, toucher une ligne éligible la coche au lieu
            // d'ouvrir la fiche.
            onTap:
                selection != null &&
                    EnrollmentRowSelection.isEligible(enrollment)
                ? () => selection.onToggle(enrollment)
                : null,
            leading: core_avatar.PersonAvatar(
              firstName: enrollment.student.firstName,
              lastName: enrollment.student.lastName,
              personId: enrollment.student.id,
              studentPhotoOf: enrollment.student.id,
              size: core_avatar.AvatarSize.sm,
              variant: _avatarVariantForStatus(
                EnrollmentStatus.fromString(enrollment.status),
              ),
            ),
            cells: [
              if (selection != null)
                DataTableCellSpec(
                  child: EnrollmentSuspensionMarks.checkbox(
                    enrollment,
                    selection,
                    l10n,
                  ),
                ),
              ..._buildCells(enrollment, isCompact, l10n),
            ],
            trailing: selection != null
                ? const DataTableTrailingSpec()
                : DataTableTrailingSpec(
                    type: DataTableTrailingType.eye,
                    tooltip: l10n.viewDetails,
                    semanticLabel: l10n.openDetailsForStudent(
                      _studentFullName(enrollment),
                    ),
                    onTap: () => widget.onViewRequested(enrollment),
                  ),
          ),
        )
        .toList(growable: false);
  }

  List<DataTableCellSpec> _buildCells(
    EnrollmentSummary enrollment,
    bool isCompact,
    AppLocalizations l10n,
  ) {
    final formattedDate = _formatDate(enrollment.student.dateOfBirth);

    // Téléphone : nom + date de naissance en sous-texte → 1 seule colonne Élève.
    if (isCompact) {
      return [
        DataTableCellSpec(
          text: _studentFullName(enrollment),
          variant: DataTableCellTextVariant.strong,
          color: _identityColor(enrollment),
          secondaryText: formattedDate,
          secondaryVariant: DataTableCellTextVariant.mono,
        ),
        _statusCell(enrollment, l10n),
      ];
    }

    return [
      DataTableCellSpec(
        text: _studentFullName(enrollment),
        variant: DataTableCellTextVariant.strong,
        color: _identityColor(enrollment),
      ),
      DataTableCellSpec(
        text: formattedDate,
        variant: DataTableCellTextVariant.mono,
      ),
      _statusCell(enrollment, l10n),
    ];
  }

  DataTableCellSpec _statusCell(
    EnrollmentSummary enrollment,
    AppLocalizations l10n,
  ) {
    // Statut métier + (si brouillon local) badge « Brouillon » sur la même
    // ligne. Chaque badge est borné (le FittedBox de la cellule impose des
    // contraintes non bornées ; le `Flexible` interne du badge casserait sinon).
    final status = EnrollmentStatus.fromString(enrollment.status);
    return DataTableCellSpec(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 122),
            // Un dossier RE distingue « En cours » (brouillon local) de
            // « Réinscrit » (finalisé/synchronisé) — axe syncState,
            // indépendant du statut métier. PRE lit directement le statut
            // métier (2 pastilles seulement — testé AVANT
            // `isReenrollmentCandidate`, type-agnostique, qui classerait
            // sinon à tort un candidat PRE brut comme « À réinscrire »).
            // « À réinscrire » pour un candidat RE N-1 non commencé, sinon
            // statut métier générique — même logique que la carte grille.
            child: enrollment.isSuspended
                ? EnrollmentSuspensionMarks.badge(enrollment, l10n)
                : enrollment.isReEnrollment
                ? StatusBadge.enrollmentReEnrollment(
                    label: enrollment.isLocalDraft
                        ? l10n.enrollmentStatusInProgress
                        : l10n.enrollmentReRegisteredBadge,
                  )
                : enrollment.isPreEnrollment
                ? (status == EnrollmentStatus.completed
                      ? StatusBadge.enrollmentCompleted(
                          label: l10n.enrollmentStatusPreRegistered,
                        )
                      : StatusBadge.enrollmentInProgress(
                          label: l10n.enrollmentStatusInProgress,
                        ))
                : enrollment.isReenrollmentCandidate
                ? StatusBadge.enrollmentPending(
                    label: l10n.enrollmentReenrollmentCandidateBadge,
                  )
                : EnrollmentStatusBadge(status: status),
          ),
          if (enrollment.isLocalDraft) ...[
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: StatusBadge.draft(
                label: l10n.enrollmentDraftBadge,
                size: StatusBadgeSize.small,
              ),
            ),
          ],
          // Axe synchro (picto seul, appui long pour le libellé) : coche verte
          // = acquitté, sablier orange = en file, triangle rouge = refusé et
          // non rejoué. Rien pour un brouillon ni pour un candidat du vivier.
          if (SyncStateIcon.isVisible(enrollment.syncState)) ...[
            const SizedBox(width: AppSpacing.xs),
            SyncStateIcon(state: enrollment.syncState),
          ],
        ],
      ),
    );
  }

  void _onSortChanged(int column, bool ascending) {
    if (column < 0 || column >= EnrollmentSortColumn.values.length) return;

    setState(() {
      _sortColumn = EnrollmentSortColumn.values[column];
      _sortAscending = ascending;
    });
  }

  /// L'identité d'un élève désactivé s'estompe ; son statut reste écrit.
  Color? _identityColor(EnrollmentSummary enrollment) => enrollment.isSuspended
      ? AppColors.textPrimary.withValues(
          alpha: EnrollmentSuspensionMarks.suspendedOpacity,
        )
      : null;

  String _studentFullName(EnrollmentSummary enrollment) {
    final parts = <String>[
      enrollment.student.lastName,
      enrollment.student.surname,
      enrollment.student.firstName,
    ].where((value) => value.trim().isNotEmpty);

    return parts.join(' ');
  }

  core_avatar.AvatarVariant _avatarVariantForStatus(EnrollmentStatus status) {
    return switch (status) {
      EnrollmentStatus.completed ||
      EnrollmentStatus.validated => core_avatar.AvatarVariant.solid,
      _ => core_avatar.AvatarVariant.outlined,
    };
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw;
  }
}
