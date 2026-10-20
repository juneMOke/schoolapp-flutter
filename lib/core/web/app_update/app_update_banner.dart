import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/web/app_update/app_update_cubit.dart';
import 'package:school_app_flutter/core/web/page_reload.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Une nouvelle version est disponible — Recharger », au-dessus de toutes
/// les routes, dès qu'[AppUpdateCubit] a vu un nouveau déploiement.
///
/// Recharger n'est jamais imposé : une saisie en cours se termine d'abord, et
/// sa garde (`beforeunload`) fait encore demander le navigateur.
class AppUpdateBanner extends StatelessWidget {
  final Widget child;

  /// Le geste « Recharger » ; la page par défaut.
  final VoidCallback onReload;

  const AppUpdateBanner({
    super.key,
    required this.child,
    this.onReload = reloadPage,
  });

  @override
  Widget build(BuildContext context) => BlocBuilder<AppUpdateCubit, bool>(
    builder: (context, available) => Column(
      children: [
        if (available) _Bar(onReload: onReload),
        Expanded(child: child),
      ],
    ),
  );
}

class _Bar extends StatelessWidget {
  final VoidCallback onReload;

  const _Bar({required this.onReload});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.info,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                size: AppSpacing.lg,
                color: AppColors.blancCasse,
              ),
              Text(
                l10n.appUpdateAvailable,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.blancCasse,
                ),
              ),
              TextButton(
                onPressed: onReload,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.blancCasse,
                  textStyle: AppTypography.labelMedium,
                ),
                child: Text(l10n.appUpdateReload),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
