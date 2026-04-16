import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// ─── Couleurs & labels par statut ─────────────────────────────────────────────

extension EnrollmentStatusColor on EnrollmentStatus {
  Color get backgroundColor {
    switch (this) {
      case EnrollmentStatus.preRegistered:
        return const Color(0xFFEFF6FF);
      case EnrollmentStatus.inProgress:
        return const Color(0xFFFFFBEB);
      case EnrollmentStatus.adminCompleted:
        return const Color(0xFFF5F3FF);
      case EnrollmentStatus.financialCompleted:
        return const Color(0xFFECFDF5);
      case EnrollmentStatus.completed:
        return const Color(0xFFD1FAE5);
      case EnrollmentStatus.validated:
        return const Color(0xFFDCFCE7);
      case EnrollmentStatus.cancelled:
        return const Color(0xFFFEF2F2);
      case EnrollmentStatus.rejected:
        return const Color(0xFFFFEDE8);
      case EnrollmentStatus.pending:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get foregroundColor {
    switch (this) {
      case EnrollmentStatus.preRegistered:
        return const Color(0xFF1D4ED8);
      case EnrollmentStatus.inProgress:
        return const Color(0xFFB45309);
      case EnrollmentStatus.adminCompleted:
        return const Color(0xFF6D28D9);
      case EnrollmentStatus.financialCompleted:
        return const Color(0xFF0D9488);
      case EnrollmentStatus.completed:
        return const Color(0xFF059669);
      case EnrollmentStatus.validated:
        return const Color(0xFF16A34A);
      case EnrollmentStatus.cancelled:
        return const Color(0xFFDC2626);
      case EnrollmentStatus.rejected:
        return const Color(0xFFEA580C);
      case EnrollmentStatus.pending:
        return const Color(0xFF6B7280);
    }
  }

  String get label {
    switch (this) {
      case EnrollmentStatus.preRegistered:
        return 'Pré-inscrit';
      case EnrollmentStatus.inProgress:
        return 'En cours';
      case EnrollmentStatus.adminCompleted:
        return 'Admin complété';
      case EnrollmentStatus.financialCompleted:
        return 'Finance complétée';
      case EnrollmentStatus.completed:
        return 'Complété';
      case EnrollmentStatus.validated:
        return 'Validé';
      case EnrollmentStatus.cancelled:
        return 'Annulé';
      case EnrollmentStatus.rejected:
        return 'Rejeté';
      case EnrollmentStatus.pending:
        return 'En attente';
    }
  }
}

// ─── Colonnes triables ────────────────────────────────────────────────────────

enum _SortColumn { nom, postnom, prenom, dateNaissance }

// ─── Widget principal ─────────────────────────────────────────────────────────

class EnrollmentDataTable extends StatefulWidget {
  final List<EnrollmentSummary> enrollments;
  final bool isLoading;
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const EnrollmentDataTable({
    super.key,
    required this.enrollments,
    required this.onViewRequested,
    this.isLoading = false,
  });

  @override
  State<EnrollmentDataTable> createState() => _EnrollmentDataTableState();
}

class _EnrollmentDataTableState extends State<EnrollmentDataTable> {
  _SortColumn _sortColumn = _SortColumn.nom;
  bool _sortAscending = true;

  List<EnrollmentSummary> get _sorted {
    final list = [...widget.enrollments];
    list.sort((a, b) {
      final s = a.student;
      final t = b.student;
      String valA, valB;
      switch (_sortColumn) {
        case _SortColumn.nom:
          valA = s.lastName;
          valB = t.lastName;
        case _SortColumn.postnom:
          valA = s.surname;
          valB = t.surname;
        case _SortColumn.prenom:
          valA = s.firstName;
          valB = t.firstName;
        case _SortColumn.dateNaissance:
          valA = s.dateOfBirth;
          valB = t.dateOfBirth;
      }
      final cmp = valA.compareTo(valB);
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  void _onSort(_SortColumn col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = col;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) return _buildLoadingState(l10n);
    if (widget.enrollments.isEmpty) return _buildEmptyState(l10n);

    final sorted = _sorted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header colonnes ──
        _SortableHeader(
          sortColumn: _sortColumn,
          ascending: _sortAscending,
          onSort: _onSort,
          l10n: l10n,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

        // ── Lignes scrollables: header/form restent visibles ──
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (context, index) => _DataRow(
            enrollment: sorted[index],
            isEven: index.isEven,
            onViewRequested: widget.onViewRequested,
          ),
        ),

        // ── Pied : compteur ──
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        _TableFooter(count: sorted.length),
      ],
    );
  }

  // ── États vide / chargement ───────────────────────────────────────────────

  Widget _buildLoadingState(AppLocalizations l10n) {
    return _StateShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loadingStudents,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return _StateShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person_search_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noResultsFound,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aucun élève ne correspond à vos critères de recherche.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wrapper pour états vide / chargement ─────────────────────────────────────

class _StateShell extends StatelessWidget {
  final Widget child;
  const _StateShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Center(child: child),
    );
  }
}

// ─── Header triable ───────────────────────────────────────────────────────────

class _SortableHeader extends StatelessWidget {
  final _SortColumn sortColumn;
  final bool ascending;
  final ValueChanged<_SortColumn> onSort;
  final AppLocalizations l10n;

  const _SortableHeader({
    required this.sortColumn,
    required this.ascending,
    required this.onSort,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          const SizedBox(width: 30),
          const SizedBox(width: 8),
          _SortCell(
            'Nom',
            _SortColumn.nom,
            flex: 3,
            sortColumn: sortColumn,
            ascending: ascending,
            onSort: onSort,
          ),
          _SortCell(
            'Postnom',
            _SortColumn.postnom,
            flex: 3,
            sortColumn: sortColumn,
            ascending: ascending,
            onSort: onSort,
          ),
          _SortCell(
            'Prénom',
            _SortColumn.prenom,
            flex: 3,
            sortColumn: sortColumn,
            ascending: ascending,
            onSort: onSort,
          ),
          _SortCell(
            l10n.dateOfBirth,
            _SortColumn.dateNaissance,
            flex: 2,
            sortColumn: sortColumn,
            ascending: ascending,
            onSort: onSort,
          ),
          const Expanded(flex: 2, child: _HeaderLabel('Statut')),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF94A3B8),
      letterSpacing: 0.9,
    ),
  );
}

class _SortCell extends StatelessWidget {
  final String label;
  final _SortColumn column;
  final int flex;
  final _SortColumn sortColumn;
  final bool ascending;
  final ValueChanged<_SortColumn> onSort;

  const _SortCell(
    this.label,
    this.column, {
    required this.flex,
    required this.sortColumn,
    required this.ascending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? AppTheme.primaryColor
                        : const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  key: ValueKey('${column.name}_$ascending'),
                  isActive
                      ? (ascending
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded)
                      : Icons.unfold_more_rounded,
                  size: 12,
                  color: isActive
                      ? AppTheme.primaryColor
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ligne de données ─────────────────────────────────────────────────────────

class _DataRow extends StatefulWidget {
  final EnrollmentSummary enrollment;
  final bool isEven;
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const _DataRow({
    required this.enrollment,
    required this.isEven,
    required this.onViewRequested,
  });

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = EnrollmentStatus.fromString(widget.enrollment.status);
    final student = widget.enrollment.student;
    final initials = _initials(student.lastName, student.firstName);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFFF0F6FF)
              : widget.isEven
              ? AppTheme.surfaceColor
              : const Color(0xFFFAFBFC),
          border: _hovered
              ? const Border(
                  left: BorderSide(color: AppTheme.primaryColor, width: 3),
                )
              : const Border(
                  left: BorderSide(color: Colors.transparent, width: 3),
                ),
        ),
        child: Row(
          children: [
            // Avatar initiales
            _Avatar(initials: initials, color: _avatarColor(student.lastName)),
            const SizedBox(width: 8),
            _Cell(student.lastName, flex: 3, bold: true),
            _Cell(student.surname, flex: 3),
            _Cell(student.firstName, flex: 3),
            _Cell(_formatDate(student.dateOfBirth), flex: 2, mono: true),
            Expanded(flex: 2, child: _StatusChip(status: status)),
            _EyeButton(onTap: () => widget.onViewRequested(widget.enrollment)),
          ],
        ),
      ),
    );
  }

  String _initials(String last, String first) {
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    return '$l$f';
  }

  Color _avatarColor(String seed) {
    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF84CC16),
    ];
    final idx = seed.isNotEmpty ? seed.codeUnitAt(0) % palette.length : 0;
    return palette[idx];
  }

  String _formatDate(String raw) {
    try {
      final p = raw.split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    } catch (_) {}
    return raw;
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;

  const _Avatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Cellule de données ───────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final bool mono;

  const _Cell(
    this.text, {
    required this.flex,
    this.bold = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text.isNotEmpty ? text : '—',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          fontFamily: mono ? 'monospace' : null,
          color: bold ? AppTheme.textPrimaryColor : const Color(0xFF4B5563),
          letterSpacing: mono ? 0.3 : 0,
        ),
      ),
    );
  }
}

// ─── Badge statut ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final EnrollmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 122),
        decoration: BoxDecoration(
          color: status.backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: status.foregroundColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: status.foregroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: status.foregroundColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                status.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: status.foregroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bouton œil ───────────────────────────────────────────────────────────────

class _EyeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _EyeButton({required this.onTap});

  @override
  State<_EyeButton> createState() => _EyeButtonState();
}

class _EyeButtonState extends State<_EyeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.viewDetails,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.visibility_outlined,
              size: 16,
              color: _hovered ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pied de tableau ──────────────────────────────────────────────────────────

class _TableFooter extends StatelessWidget {
  final int count;
  const _TableFooter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count résultat${count > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
