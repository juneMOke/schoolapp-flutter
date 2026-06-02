import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SidebarHeaderCollapsed extends StatelessWidget {
  const SidebarHeaderCollapsed({super.key});

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
          child: InkWell(
            onTap: () =>
                context.read<NavigationBloc>().add(const SidebarToggled()),
            borderRadius: AppRadius.brSm,
            child: Tooltip(
              message: l10n.homeSidebarExpandTooltip,
              child: SizedBox(
                width: AppDimensions.minTouchTarget,
                height: AppDimensions.minTouchTarget,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.textOnDark.withValues(alpha: 0.08),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: const SizedBox(
                      width: AppDimensions.minTouchTarget,
                      height: AppDimensions.minTouchTarget,
                      child: Center(
                        child: EteeloLogo(
                          variant: EteeloLogoVariant.symbolOnDark,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
