/// Une page découpée côté client d'une liste déjà filtrée.
class ClientPage<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const ClientPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });
}

/// Découpage de page **côté client**, pour les listings servis depuis une
/// lecture locale complète (le DAO ne pagine pas).
///
/// Source unique du bornage, qui a plus de pièges qu'il n'y paraît : une liste
/// vide donne `totalPages == 0`, et `clamp(0, totalPages - 1)` lèverait alors
/// (`lowerLimit > upperLimit`). Une taille de page nulle ou négative diviserait
/// par zéro. Les deux cas sont traités ici, une fois.
class ClientSidePaginator {
  const ClientSidePaginator._();

  static ClientPage<T> paginate<T>(
    List<T> all, {
    required int page,
    required int size,
  }) {
    final effectiveSize = size > 0 ? size : 1;
    final totalElements = all.length;
    final totalPages = totalElements == 0
        ? 0
        : (totalElements + effectiveSize - 1) ~/ effectiveSize;
    final clampedPage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
    final start = clampedPage * effectiveSize;
    final end = start + effectiveSize < totalElements
        ? start + effectiveSize
        : totalElements;
    final content = start >= totalElements ? <T>[] : all.sublist(start, end);
    return ClientPage<T>(
      content: content,
      page: clampedPage,
      size: effectiveSize,
      totalElements: totalElements,
      totalPages: totalPages,
    );
  }
}
