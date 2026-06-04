import 'package:flutter/material.dart';

class SearchFormCompact extends StatelessWidget {
  final List<Widget> fields;
  final Widget actions;
  final double spacing;
  final double fieldWidth;

  const SearchFormCompact({
    super.key,
    required this.fields,
    required this.actions,
    required this.spacing,
    required this.fieldWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...fields.map((field) => SizedBox(width: fieldWidth, child: field)),
            SizedBox(
              width: constraints.maxWidth,
              child: Align(alignment: Alignment.centerRight, child: actions),
            ),
          ],
        );
      },
    );
  }
}
