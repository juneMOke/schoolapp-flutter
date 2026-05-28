import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';

class _Outer {
  final int order;
  final List<_Inner> inners;

  const _Outer({required this.order, required this.inners});
}

class _Inner {
  final int order;
  final String value;

  const _Inner({required this.order, required this.value});
}

void main() {
  group('SortedNestedOptionsHelper.buildFlat', () {
    test('returns flat items sorted by outer then inner order', () {
      final outers = [
        const _Outer(
          order: 2,
          inners: [
            _Inner(order: 4, value: 'B4'),
            _Inner(order: 1, value: 'B1'),
          ],
        ),
        const _Outer(
          order: 1,
          inners: [
            _Inner(order: 3, value: 'A3'),
            _Inner(order: 2, value: 'A2'),
          ],
        ),
      ];

      final result =
          SortedNestedOptionsHelper.buildFlat<_Outer, _Inner, String>(
            outers: outers,
            outerOrder: (outer) => outer.order,
            inners: (outer) => outer.inners,
            innerOrder: (inner) => inner.order,
            mapItem: (outer, inner) => '${outer.order}:${inner.value}',
          );

      expect(result, ['1:A2', '1:A3', '2:B1', '2:B4']);
    });

    test('returns empty list when input is empty', () {
      final result =
          SortedNestedOptionsHelper.buildFlat<_Outer, _Inner, String>(
            outers: const [],
            outerOrder: (outer) => outer.order,
            inners: (outer) => outer.inners,
            innerOrder: (inner) => inner.order,
            mapItem: (outer, inner) => inner.value,
          );

      expect(result, isEmpty);
    });
  });
}
