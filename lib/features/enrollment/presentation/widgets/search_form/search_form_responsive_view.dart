import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';

class SearchFormResponsiveView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Widget> fields;
  final Widget actions;

  const SearchFormResponsiveView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.search_rounded,
    this.accentColor = AppColors.bleuArdoise,
    required this.fields,
    required this.actions,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloGridView(
            itemCount: fields.length,
            itemBuilder: (_, i) => fields[i],
            minItemWidth: AppDimensions.filterGridMinItemWidth,
            spacing: AppSpacing.gridGap,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.gridGap),
          actions,
        ],
      ),
    );
  }
}
