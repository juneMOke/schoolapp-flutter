import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Enveloppe globale (montée via `MaterialApp.router` builder) qui ajoute un
/// bandeau « hors-ligne » au-dessus de l'app quand on affiche des données en
/// cache parce que le rafraîchissement distant a échoué (cf.
/// [BootstrapState.isStale]). Hors de ce cas, le bandeau est absent (aucun
/// décalage de layout).
class BootstrapOfflineBanner extends StatelessWidget {
  const BootstrapOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BootstrapBloc, BootstrapState>(
      buildWhen: (previous, current) => previous.isStale != current.isStale,
      builder: (context, state) {
        return Column(
          children: [
            if (state.isStale) const _OfflineBar(),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Material : fournit le DefaultTextStyle au-dessus du Navigator.
    return Material(
      color: AppColors.warning,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: AppColors.blancCasse,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.bootstrapOfflineBanner,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.blancCasse,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
