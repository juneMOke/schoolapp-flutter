import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_compact.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_desktop.dart';

class SearchFormResponsiveView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Widget> fields;
  final Widget actions;
  final double spacing;
  final double minFieldWidth;
  final double maxFieldWidth;
  final double actionsWideSpacing;

  const SearchFormResponsiveView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.search_rounded,
    this.accentColor = AppColors.bleuArdoise,
    required this.fields,
    required this.actions,
    this.spacing = 10,
    this.minFieldWidth = 170,
    this.maxFieldWidth = 360,
    this.actionsWideSpacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return BiToneSectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      surfaceColor: AppColors.surfaceRaised,
      bodyPadding: const EdgeInsets.all(AppSpacing.xl - 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.formWideMin;
          final isMedium = constraints.maxWidth >= AppBreakpoints.formMediumMin;
          final columns = isMedium ? 3 : 1;
          final fieldWidth =
              ((constraints.maxWidth - ((columns - 1) * spacing)) / columns)
                  .clamp(minFieldWidth, maxFieldWidth)
                  .toDouble();

          if (isWide) {
            return SearchFormDesktop(
              fields: fields,
              actions: actions,
              spacing: spacing,
              actionsWideSpacing: actionsWideSpacing,
            );
          }

          return SearchFormCompact(
            fields: fields,
            actions: actions,
            spacing: spacing,
            fieldWidth: fieldWidth,
          );
        },
      ),
    );
  }
}
