import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_card.dart';

class SearchFormResponsiveView extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final List<Widget> fields;
  final Widget actions;
  final double spacing;
  final double minFieldWidth;
  final double maxFieldWidth;
  final double titleBottomSpacing;
  final double subtitleBottomSpacing;
  final double actionsWideSpacing;

  const SearchFormResponsiveView({
    super.key,
    required this.title,
    this.subtitle,
    required this.fields,
    required this.actions,
    this.spacing = 10,
    this.minFieldWidth = 170,
    this.maxFieldWidth = 360,
    this.titleBottomSpacing = 10,
    this.subtitleBottomSpacing = 10,
    this.actionsWideSpacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SearchFormCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.formWideMin;
          final isMedium = constraints.maxWidth >= AppBreakpoints.formMediumMin;
          final columns = isMedium ? 3 : 1;
          final fieldWidth =
              ((constraints.maxWidth - ((columns - 1) * spacing)) / columns)
                  .clamp(minFieldWidth, maxFieldWidth)
                  .toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              SizedBox(height: subtitle == null ? titleBottomSpacing : 6),
              if (subtitle != null) ...[
                subtitle!,
                SizedBox(height: subtitleBottomSpacing),
              ],
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...fields.expand(
                      (field) => [Expanded(child: field), SizedBox(width: spacing)],
                    ),
                    SizedBox(width: actionsWideSpacing),
                    actions,
                  ],
                )
              else
                Wrap(
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
                ),
            ],
          );
        },
      ),
    );
  }
}
