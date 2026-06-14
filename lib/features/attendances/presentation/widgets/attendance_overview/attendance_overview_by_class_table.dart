import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/class_attendance_stat.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_format.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_palette.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Colonne triable du tableau de presence par classe.
enum _SortColumn { presence, unjustified }

/// Largeur minimale du tableau ; en deca on bascule en defilement horizontal.
const double _kMinTableWidth = 680;

/// Repartition des flex par colonne :
/// Classe | Niveau | Presence | Justif. | Non justif. | Repartition.
const List<int> _kColumnFlex = [15, 10, 9, 9, 9, 17];

/// Tableau de presence par classe (lecture seule, triable).
///
/// L'ordre par defaut est celui recu (deja trie par niveau cote backend) : on
/// ne re-trie pas tant que l'utilisateur n'a pas active une colonne. Les
/// colonnes Presence et Non justif. sont triables ; un 3e tap revient a l'ordre
/// recu (etat de tri nullable).
class AttendanceOverviewByClassTable extends StatefulWidget {
  final List<ClassAttendanceStat> classes;

  const AttendanceOverviewByClassTable({super.key, required this.classes});

  @override
  State<AttendanceOverviewByClassTable> createState() =>
      _AttendanceOverviewByClassTableState();
}

class _AttendanceOverviewByClassTableState
    extends State<AttendanceOverviewByClassTable> {
  /// Colonne de tri active (null = ordre recu du serveur).
  _SortColumn? _sortColumn;

  /// Sens du tri quand une colonne est active.
  bool _ascending = false;

  /// Cycle de tri sur l'en-tete tape : null -> desc -> asc -> null (ordre recu).
  void _onHeaderTap(_SortColumn column) {
    setState(() {
      if (_sortColumn != column) {
        // Nouvelle colonne : on demarre en decroissant (les pires/meilleurs en tete).
        _sortColumn = column;
        _ascending = false;
      } else if (!_ascending) {
        // 2e tap sur la meme colonne : on passe en croissant.
        _ascending = true;
      } else {
        // 3e tap : retour a l'ordre recu.
        _sortColumn = null;
      }
    });
  }

  /// Lignes a afficher : copie triee si une colonne est active, sinon l'ordre recu.
  List<ClassAttendanceStat> get _rows {
    final column = _sortColumn;
    if (column == null) return widget.classes;

    double valueOf(ClassAttendanceStat stat) => switch (column) {
      _SortColumn.presence => stat.presenceRate,
      _SortColumn.unjustified => stat.unjustifiedAbsenceRate,
    };

    // Tri STABLE : départage les ex æquo par l'index reçu (ordre par niveau du
    // serveur), pour ne pas mélanger les classes de même taux (List.sort de
    // Dart n'est pas garanti stable).
    final indexed = [
      for (var i = 0; i < widget.classes.length; i++) (i, widget.classes[i]),
    ];
    indexed.sort((a, b) {
      final cmp = valueOf(a.$2).compareTo(valueOf(b.$2));
      final primary = _ascending ? cmp : -cmp;
      return primary != 0 ? primary : a.$1.compareTo(b.$1);
    });
    return [for (final entry in indexed) entry.$2];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AttendanceOverviewCard(
      title: l10n.attendanceOverviewByClassTitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = _buildTable(context, l10n);
          // En largeur contrainte, on autorise le defilement horizontal pour
          // ne jamais ecraser les cellules.
          if (constraints.maxWidth >= _kMinTableWidth) return table;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: _kMinTableWidth, child: table),
          );
        },
      ),
    );
  }

  /// Conteneur borde : en-tete + lignes de donnees alternees.
  Widget _buildTable(BuildContext context, AppLocalizations l10n) {
    final rows = _rows;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(context, l10n),
          for (var i = 0; i < rows.length; i++)
            _buildDataRow(context, l10n, rows[i], isEven: i.isEven),
        ],
      ),
    );
  }

  /// En-tete : libelles petits, majuscules, semi-gras ; colonnes Presence et
  /// Non justif. tapables avec une fleche de sens de tri.
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: Row(
        children: [
          _headerCell(l10n.attendanceOverviewColClass, flex: _kColumnFlex[0]),
          _headerCell(l10n.attendanceOverviewColLevel, flex: _kColumnFlex[1]),
          _sortableHeaderCell(
            label: l10n.attendanceOverviewColPresence,
            column: _SortColumn.presence,
            flex: _kColumnFlex[2],
          ),
          _headerCell(
            l10n.attendanceOverviewColJustified,
            flex: _kColumnFlex[3],
            alignEnd: true,
          ),
          _sortableHeaderCell(
            label: l10n.attendanceOverviewColUnjustified,
            column: _SortColumn.unjustified,
            flex: _kColumnFlex[4],
          ),
          _headerCell(
            l10n.attendanceOverviewColDistribution,
            flex: _kColumnFlex[5],
          ),
        ],
      ),
    );
  }

  /// Cellule d'en-tete statique (texte seul).
  Widget _headerCell(String label, {required int flex, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: AppTextStyles.badge.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  /// Cellule d'en-tete triable (alignee a droite, comme les valeurs) : InkWell +
  /// fleche de sens uniquement sur la colonne active.
  Widget _sortableHeaderCell({
    required String label,
    required _SortColumn column,
    required int flex,
  }) {
    final isActive = _sortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _onHeaderTap(column),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.end,
                style: AppTextStyles.badge.copyWith(
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: AppDimensions.spacingXS),
              Icon(
                _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: AppColors.textPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Ligne de donnees : nom, pastille de cycle, taux, barre de repartition.
  Widget _buildDataRow(
    BuildContext context,
    AppLocalizations l10n,
    ClassAttendanceStat stat, {
    required bool isEven,
  }) {
    final isAlert =
        stat.unjustifiedAbsenceRate >=
        AppDimensions.attendanceOverviewUnjustifiedAlertThreshold;

    // Resume textuel pour l'accessibilite (l'info ne repose pas sur la couleur).
    final a11yLabel =
        '${stat.className} · '
        '${l10n.attendanceOverviewColPresence} '
        '${l10n.attendanceOverviewRateValue(AttendanceOverviewFormat.rate(stat.presenceRate, context))} · '
        '${l10n.attendanceOverviewColJustified} '
        '${l10n.attendanceOverviewRateValue(AttendanceOverviewFormat.rate(stat.justifiedAbsenceRate, context))} · '
        '${l10n.attendanceOverviewColUnjustified} '
        '${l10n.attendanceOverviewRateValue(AttendanceOverviewFormat.rate(stat.unjustifiedAbsenceRate, context))}';

    return Semantics(
      label: a11yLabel,
      child: Container(
        // Fond alterne discret (plus clair que l'en-tete surfaceAlt, pour
        // distinguer l'en-tete du corps).
        color: isEven ? null : AppColors.surfaceAlt.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: _kColumnFlex[0],
              child: Text(
                stat.className,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(flex: _kColumnFlex[1], child: _cyclePill(stat.cycle)),
            _rateCell(
              context,
              l10n,
              stat.presenceRate,
              color: AppColors.vertSavane,
              bold: true,
              flex: _kColumnFlex[2],
            ),
            _rateCell(
              context,
              l10n,
              stat.justifiedAbsenceRate,
              color: AppColors.warning,
              flex: _kColumnFlex[3],
            ),
            _rateCell(
              context,
              l10n,
              stat.unjustifiedAbsenceRate,
              color: isAlert ? AppColors.error : AppColors.textSecondary,
              bold: isAlert,
              flex: _kColumnFlex[4],
            ),
            Expanded(
              flex: _kColumnFlex[5],
              child: Padding(
                padding: const EdgeInsets.only(left: AppDimensions.spacingS),
                child: _distributionBar(stat),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pastille teintee du cycle (fond a ~12 % d'alpha, texte couleur cycle).
  Widget _cyclePill(String cycle) {
    final color = AttendanceOverviewPalette.cycleColor(cycle);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          cycle,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.badge.copyWith(color: color),
        ),
      ),
    );
  }

  /// Cellule de taux alignee a droite, couleur et graisse selon le contexte.
  Widget _rateCell(
    BuildContext context,
    AppLocalizations l10n,
    double rate, {
    required Color color,
    required int flex,
    bool bold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        l10n.attendanceOverviewRateValue(
          AttendanceOverviewFormat.rate(rate, context),
        ),
        textAlign: TextAlign.end,
        style: (bold ? AppTextStyles.bodyStrong : AppTextStyles.body).copyWith(
          color: color,
          fontFeatures: AppTextStyles.tabularFigures,
        ),
      ),
    );
  }

  /// Mini barre empilee 3 segments (presence / justifiee / non justifiee), flex
  /// proportionnel au taux (precision 0,1 % via *10), coins arrondis.
  Widget _distributionBar(ClassAttendanceStat stat) {
    final segments = <(double, Color)>[
      (stat.presenceRate, AppColors.vertSavane),
      (stat.justifiedAbsenceRate, AppColors.warning),
      (stat.unjustifiedAbsenceRate, AppColors.error),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: AppColors.surfaceAlt,
        child: SizedBox(
          height: AppDimensions.attendanceOverviewClassSplitBarHeight,
          child: Row(
            children: [
              for (final (rate, color) in segments)
                Expanded(
                  flex: (rate * 10).round(),
                  child: ColoredBox(color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
