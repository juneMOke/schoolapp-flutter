import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// ─── Enum de tri (privé au fichier) ───────────────────────────────────────────

enum _SortCol { nom, postnom, prenom }

// ─── Widget public ────────────────────────────────────────────────────────────

/// Tableau des élèves pour la facturation.
///
/// Gère le tri local des colonnes ainsi que les états chargement et vide.
/// Les sous-composants (header, lignes, footer) sont privés au fichier.
class FacturationDataTable extends StatefulWidget {
  final List<EnrollmentSummary> summaries;
  final bool isLoading;
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const FacturationDataTable({
    super.key,
    required this.summaries,
    required this.isLoading,
    required this.onViewRequested,
  });

  @override
  State<FacturationDataTable> createState() => _FacturationDataTableState();
}

class _FacturationDataTableState extends State<FacturationDataTable> {
  _SortCol _sortCol = _SortCol.nom;
  bool _sortAsc = true;

  List<EnrollmentSummary> get _sorted {
    final list = [...widget.summaries];
    list.sort((a, b) {
      final valA = switch (_sortCol) {
        _SortCol.nom => a.student.lastName,
        _SortCol.postnom => a.student.surname,
        _SortCol.prenom => a.student.firstName,
      };
      final valB = switch (_sortCol) {
        _SortCol.nom => b.student.lastName,
        _SortCol.postnom => b.student.surname,
        _SortCol.prenom => b.student.firstName,
      };
      final cmp = valA.compareTo(valB);
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _onSort(_SortCol col) => setState(() {
        if (_sortCol == col) {
          _sortAsc = !_sortAsc;
        } else {
          _sortCol = col;
          _sortAsc = true;
        }
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) return _LoadingState(l10n: l10n);
    if (widget.summaries.isEmpty) return _EmptyState(l10n: l10n);

    final sorted = _sorted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TableHeader(
          sortCol: _sortCol,
          ascending: _sortAsc,
          onSort: _onSort,
          l10n: l10n,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (_, i) => _TableRow(
            summary: sorted[i],
            isEven: i.isEven,
            onViewRequested: widget.onViewRequested,
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        _TableFooter(
          pageCount: sorted.length,
          totalCount: widget.summaries.length,
        ),
      ],
    );
  }
}

// ─── États loading / empty ────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  final AppLocalizations l10n;
  const _LoadingState({required this.l10n});

  @override
  Widget build(BuildContext context) => _StateShell(
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

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) => _StateShell(
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
            Text(
              l10n.facturationNoResultsDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

class _StateShell extends StatelessWidget {
  final Widget child;
  const _StateShell({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Center(child: child),
      );
}

// ─── Header triable ───────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final _SortCol sortCol;
  final bool ascending;
  final ValueChanged<_SortCol> onSort;
  final AppLocalizations l10n;

  const _TableHeader({
    required this.sortCol,
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
          const SizedBox(width: 38), // avatar placeholder
          _SortCell(l10n.lastName, _SortCol.nom,
              flex: 3, sortCol: sortCol, asc: ascending, onSort: onSort),
          _SortCell(l10n.surname, _SortCol.postnom,
              flex: 3, sortCol: sortCol, asc: ascending, onSort: onSort),
          _SortCell(l10n.firstName, _SortCol.prenom,
              flex: 3, sortCol: sortCol, asc: ascending, onSort: onSort),
          Expanded(
            flex: 2,
            child: Text(
              l10n.facturationActionsColumnLabel.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SortCell extends StatelessWidget {
  final String label;
  final _SortCol column;
  final int flex;
  final _SortCol sortCol;
  final bool asc;
  final ValueChanged<_SortCol> onSort;

  const _SortCell(
    this.label,
    this.column, {
    required this.flex,
    required this.sortCol,
    required this.asc,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortCol == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(
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
                  key: ValueKey('${column.name}_$asc'),
                  isActive
                      ? (asc
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded)
                      : Icons.unfold_more_rounded,
                  size: 12,
                  color:
                      isActive ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
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

class _TableRow extends StatefulWidget {
  final EnrollmentSummary summary;
  final bool isEven;
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const _TableRow({
    required this.summary,
    required this.isEven,
    required this.onViewRequested,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = widget.summary.student;
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
                  left: BorderSide(color: AppTheme.primaryColor, width: 3))
              : const Border(
                  left: BorderSide(color: Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            _Avatar(initials: initials, seed: student.lastName),
            const SizedBox(width: 8),
            _Cell(student.lastName, flex: 3, bold: true),
            _Cell(student.surname, flex: 3),
            _Cell(student.firstName, flex: 3),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _EyeButton(
                  tooltip: l10n.facturationViewChargesLabel,
                  onTap: () => widget.onViewRequested(widget.summary),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  static String _initials(String last, String first) {
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    return '$l$f';
  }
}

// ─── Composants atomiques ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final String seed;

  const _Avatar({required this.initials, required this.seed});

  static const _palette = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF8B5CF6),
    Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF06B6D4),
    Color(0xFFEC4899), Color(0xFF84CC16),
  ];

  Color get _color {
    final idx = seed.isNotEmpty ? seed.codeUnitAt(0) % _palette.length : 0;
    return _palette[idx];
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      );
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;

  const _Cell(this.text, {required this.flex, this.bold = false});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          text.isNotEmpty ? text : '—',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: bold ? AppTheme.textPrimaryColor : const Color(0xFF4B5563),
          ),
        ),
      );
}

class _EyeButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onTap;

  const _EyeButton({required this.tooltip, required this.onTap});

  @override
  State<_EyeButton> createState() => _EyeButtonState();
}

class _EyeButtonState extends State<_EyeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: widget.tooltip,
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

// ─── Pied de tableau ──────────────────────────────────────────────────────────

class _TableFooter extends StatelessWidget {
  final int pageCount;
  final int totalCount;

  const _TableFooter({required this.pageCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = totalCount > pageCount
        ? l10n.enrollmentPageFooter(pageCount, totalCount)
        : l10n.enrollmentResultsCount(pageCount);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
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
