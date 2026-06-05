import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_density.dart';

/// Type de texte pour une cellule de table.
enum DataTableCellTextVariant { regular, strong, mono }

/// Definition d'une colonne pour un rendu de table uniforme.
class DataTableColumnDef {
  final String label;
  final int flex;
  final bool sortable;
  final int? sortIndex;

  const DataTableColumnDef({
    required this.label,
    this.flex = 1,
    this.sortable = false,
    this.sortIndex,
  });
}

/// Donnees d'une cellule textuelle.
class DataTableCellSpec {
  final String text;
  final Widget? child;
  final DataTableCellTextVariant variant;
  final TextAlign textAlign;

  const DataTableCellSpec({
    this.text = '',
    this.child,
    this.variant = DataTableCellTextVariant.regular,
    this.textAlign = TextAlign.start,
  });
}

/// Identifiant de type pour le rendu trailing.
///
/// Les consommateurs peuvent definir leurs propres types sans modifier le core.
@immutable
class DataTableTrailingType {
  final String key;

  const DataTableTrailingType(this.key);

  static const none = DataTableTrailingType('none');
  static const eye = DataTableTrailingType('eye');
  static const chevronOpen = DataTableTrailingType('chevron_open');
  static const chevronClose = DataTableTrailingType('chevron_close');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataTableTrailingType &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// Specification trailing de ligne.
class DataTableTrailingSpec {
  final DataTableTrailingType type;
  final VoidCallback? onTap;
  final String? tooltip;
  final String? semanticLabel;
  final bool enabled;

  const DataTableTrailingSpec({
    this.type = DataTableTrailingType.none,
    this.onTap,
    this.tooltip,
    this.semanticLabel,
    this.enabled = true,
  });
}

/// Representation data-driven d'une ligne de table.
class DataTableRowSpec {
  final String id;
  final String displayName;
  final Widget? leading;
  final List<DataTableCellSpec> cells;
  final DataTableTrailingSpec trailing;
  final VoidCallback? onTap;

  const DataTableRowSpec({
    required this.id,
    required this.displayName,
    required this.cells,
    this.leading,
    this.trailing = const DataTableTrailingSpec(),
    this.onTap,
  });
}

/// Configuration de pagination uniforme pour les tableaux.
///
/// Convention : [currentPage] et [totalPages] sont **1-based**.
/// - Page 1 = première page (première page visible pour l'utilisateur).
/// - Les BLoCs stockent généralement une page 0-based ; les containers
///   doivent faire `summariesPage + 1` avant de passer la valeur ici.
class DataTablePaginationConfig {
  /// Page courante, **1-based** (1 = première page).
  final int currentPage;

  /// Nombre total de pages, **1-based**.
  final int totalPages;
  final int pageSize;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isLoading;
  final String Function(int current, int total)? pageLabel;

  const DataTablePaginationConfig({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.onPrevious,
    required this.onNext,
    this.isLoading = false,
    this.pageLabel,
  });
}

/// Footer standardise de table.
class DataTableFooterConfig {
  final String label;
  final DataTablePaginationConfig? pagination;
  final int? total;
  final String? unit;

  const DataTableFooterConfig({
    required this.label,
    this.pagination,
    this.total,
    this.unit,
  });
}

/// Configuration principale de [DataTableView].
class DataTableViewConfig {
  final List<DataTableColumnDef> columns;
  final bool isLoading;
  final bool isError;
  final String? loadingLabel;
  final String? emptyLabel;
  final String? errorLabel;
  final int? sortColumnIndex;
  final bool sortAscending;
  final OnDataTableSort? onSortChanged;
  final DataTableFooterConfig? footer;
  final DataTableDensity density;
  final String? semanticsLabel;

  const DataTableViewConfig({
    required this.columns,
    this.isLoading = false,
    this.isError = false,
    this.loadingLabel,
    this.emptyLabel,
    this.errorLabel,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSortChanged,
    this.footer,
    this.density = DataTableDensity.comfortable,
    this.semanticsLabel,
  });
}

/// Interface abstraite pour une ligne de table de données.
///
/// Tout widget qui souhaite afficher une ligne dans [DataTableView] doit
/// implémenter cette interface.
abstract class DataTableRow {
  /// Identifiant unique de la ligne (utilisé pour les keys)
  String get id;

  /// Nom d'affichage principal (pour accessibilité, logs, etc.)
  String get displayName;

  /// Widget avatar à afficher (avatar d'étudiant, icone, etc.)
  Widget get avatar;

  /// Liste des widgets cellules (contenu des colonnes de données)
  ///
  /// Chaque élément doit être un widget simple (Text, Container, etc.)
  /// qu'on enrobera dans Expanded par [DataTableView].
  List<Widget> get cells;

  /// Widget trailing optionnel (bouton eye, actions, etc.)
  ///
  /// `null` → aucun widget trailing.
  Widget? get trailing;
}

/// Direction de tri pour les colonnes.
enum DataTableSortDirection { asc, desc }

/// Callback pour gérer un changement de tri.
///
/// `column` : colonne triée (numéro 0-based)
/// `ascending` : true si croissant, false si décroissant
typedef OnDataTableSort = void Function(int column, bool ascending);

/// Builder pour construire un header custom.
///
/// [sortColumn] : index de colonne activement triée (-1 si aucune)
/// [sortAscending] : direction du tri
/// [onSort] : callback appelé quand on clique sur une colonne
typedef DataTableHeaderBuilder =
    Widget Function(
      BuildContext context,
      int sortColumn,
      bool sortAscending,
      OnDataTableSort onSort,
    );

/// Builder pour construire une ligne custom.
typedef DataTableRowBuilder =
    Widget Function(
      BuildContext context,
      DataTableRow row,
      bool isEven,
      int index,
    );

/// Builder optionnel pour construire un footer custom.
typedef DataTableFooterBuilder =
    Widget Function(BuildContext context, int totalRowCount);

/// Callback appelé quand une ligne est cliquée ou sélectionnée.
typedef OnRowSelected<T extends DataTableRow> = void Function(T row);

/// Configuration optionnelle du comportement du tri.
class DataTableSortConfig {
  /// Colonne triée par défaut (0-based index)
  final int? initialSortColumn;

  /// Direction par défaut
  final bool initialSortAscending;

  /// Callback appelé quand le tri change
  final OnDataTableSort? onSortChanged;

  const DataTableSortConfig({
    this.initialSortColumn,
    this.initialSortAscending = true,
    this.onSortChanged,
  });
}

/// État de table pour tracking tri et sélection.
class DataTableState {
  final int? sortColumn;
  final bool sortAscending;
  final Set<String> selectedRowIds;

  const DataTableState({
    this.sortColumn,
    this.sortAscending = true,
    this.selectedRowIds = const {},
  });

  DataTableState copyWith({
    int? sortColumn,
    bool? sortAscending,
    Set<String>? selectedRowIds,
  }) {
    return DataTableState(
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedRowIds: selectedRowIds ?? this.selectedRowIds,
    );
  }
}
