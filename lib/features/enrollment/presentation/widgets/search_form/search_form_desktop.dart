import 'package:flutter/material.dart';

class SearchFormDesktop extends StatelessWidget {
  final List<Widget> fields;
  final Widget actions;
  final double spacing;
  final double actionsWideSpacing;

  const SearchFormDesktop({
    super.key,
    required this.fields,
    required this.actions,
    required this.spacing,
    required this.actionsWideSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          Expanded(child: fields[i]),
          if (i < fields.length - 1) SizedBox(width: spacing),
        ],
        SizedBox(width: actionsWideSpacing),
        actions,
      ],
    );
  }
}
