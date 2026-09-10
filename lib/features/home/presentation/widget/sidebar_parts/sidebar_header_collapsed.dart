import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/features/school/presentation/widget/school_brand_mark.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SidebarHeaderCollapsed extends StatelessWidget {
  const SidebarHeaderCollapsed({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logo = SchoolBrandMark.logoOf(context);

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
                      // La vignette passe en pastille pleine sous un sceau
                      // d'école : sur le Bleu Profond, un logo aux traits
                      // foncés disparaîtrait sinon.
                      color: SchoolBrandMark.plateColor(
                        logo,
                        idle: AppColors.textOnDark.withValues(alpha: 0.08),
                      ),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: SizedBox(
                      width: AppDimensions.minTouchTarget,
                      height: AppDimensions.minTouchTarget,
                      child: Center(
                        child: SchoolBrandMark(
                          logo: logo,
                          size:
                              HomeNavigationUiTokens.sidebarBrandCollapsedSize,
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
