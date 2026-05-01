class SortedNestedOptionsHelper {
  const SortedNestedOptionsHelper._();

  static List<TItemResult> buildFlat<TOuter, TInner, TItemResult>({
    required List<TOuter> outers,
    required int Function(TOuter outer) outerOrder,
    required List<TInner> Function(TOuter outer) inners,
    required int Function(TInner inner) innerOrder,
    required TItemResult Function(TOuter outer, TInner inner) mapItem,
  }) {
    return build<TOuter, TInner, TItemResult, List<TItemResult>>(
      outers: outers,
      outerOrder: outerOrder,
      inners: inners,
      innerOrder: innerOrder,
      mapInner: mapItem,
      mapOuter: (_, items) => items,
    ).expand((items) => items).toList(growable: false);
  }

  static List<TOuterResult> build<TOuter, TInner, TInnerResult, TOuterResult>({
    required List<TOuter> outers,
    required int Function(TOuter outer) outerOrder,
    required List<TInner> Function(TOuter outer) inners,
    required int Function(TInner inner) innerOrder,
    required TInnerResult Function(TOuter outer, TInner inner) mapInner,
    required TOuterResult Function(TOuter outer, List<TInnerResult> items) mapOuter,
  }) {
    final sortedOuters = [...outers]..sort((a, b) => outerOrder(a).compareTo(outerOrder(b)));

    return sortedOuters.map((outer) {
      final sortedInners = [...inners(outer)]
        ..sort((a, b) => innerOrder(a).compareTo(innerOrder(b)));

      final mappedInners = sortedInners
          .map((inner) => mapInner(outer, inner))
          .toList(growable: false);

      return mapOuter(outer, mappedInners);
    }).toList(growable: false);
  }
}
