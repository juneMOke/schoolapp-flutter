import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SidebarHeader extends StatelessWidget {
  final bool isExpanded;

  const SidebarHeader({super.key, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isExpanded ? 12 : 8,
        8,
        isExpanded ? 12 : 8,
        0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 10 : 6,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.08),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.textOnDark.withValues(alpha: 0.08)),
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.outCurve,
        switchOutCurve: AppMotion.inCurve,
        child: isExpanded ? const _ExpandedHeader() : const _CollapsedHeader(),
      ),
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  const _ExpandedHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      key: const ValueKey('expanded'),
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.terreCuite,
            borderRadius: AppRadius.brSm,
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.textOnDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.schoolApp,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textOnDark,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: l10n.homeSidebarNavigationLabel,
          hint: l10n.homeSidebarCollapseTooltip,
          toggled: true,
          child: ExcludeSemantics(
            child: IconButton(
              tooltip: l10n.homeSidebarCollapseTooltip,
              onPressed: () =>
                  context.read<NavigationBloc>().add(const SidebarToggled()),
              icon: Icon(
                Icons.menu_open_rounded,
                color: AppColors.textOnDark.withValues(alpha: 0.7),
                size: 20,
              ),
              constraints: const BoxConstraints(
                minWidth: AppDimensions.minTouchTarget,
                minHeight: AppDimensions.minTouchTarget,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsedHeader extends StatelessWidget {
  const _CollapsedHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      key: const ValueKey('collapsed'),
      child: Semantics(
        button: true,
        label: l10n.homeSidebarNavigationLabel,
        hint: l10n.homeSidebarExpandTooltip,
        toggled: false,
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: l10n.homeSidebarExpandTooltip,
            onPressed: () =>
                context.read<NavigationBloc>().add(const SidebarToggled()),
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textOnDark,
              size: 22,
            ),
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
          ),
        ),
      ),
    );
  }
}
