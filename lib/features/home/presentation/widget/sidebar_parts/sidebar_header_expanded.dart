import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SidebarHeaderExpanded extends StatelessWidget {
  const SidebarHeaderExpanded({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schoolAppLabel = l10n.schoolApp.trim();
    final sidebarTitle = schoolAppLabel.contains(' ')
        ? schoolAppLabel.replaceFirst(RegExp(r'\s+'), '\n')
        : schoolAppLabel;

    return Row(
      key: const ValueKey('expanded'),
      children: [
        const EteeloLogo(variant: EteeloLogoVariant.symbolOnDark, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            sidebarTitle,
            maxLines: 2,
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
            child: Material(
              color: AppColors.textOnDark.withValues(alpha: 0.08),
              borderRadius: AppRadius.brSm,
              child: IconButton(
                tooltip: l10n.homeSidebarCollapseTooltip,
                onPressed: () =>
                    context.read<NavigationBloc>().add(const SidebarToggled()),
                icon: Icon(
                  Icons.menu_open_rounded,
                  color: AppColors.textOnDark.withValues(alpha: 0.72),
                  size: 20,
                ),
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.minTouchTarget,
                  minHeight: AppDimensions.minTouchTarget,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
