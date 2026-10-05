import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête sombre de la séance, celui du parcours d'inscription : le
/// sur-titre or, la classe, et pendant la prise de vue le compteur « traités
/// / N » et « Terminer ».
class PhotoSessionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final PhotoSessionState state;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const PhotoSessionAppBar({
    super.key,
    required this.state,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = this.state;
    final title = switch (state) {
      SessionShooting(:final klass) => klass.name,
      SessionSummary(:final klass) => klass.name,
      _ => l10n.photoSessionChooseClass,
    };
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: AppDimensions.topBarHeight,
      foregroundColor: AppColors.textOnDark,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
          ),
        ),
      ),
      leading: IconButton(
        tooltip: l10n.previous,
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.photoSessionButton.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.orDoux,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
      actions: [
        if (state is SessionShooting) ...[
          Center(
            child: Text(
              l10n.photoSessionHandled(state.handled, state.queue.length),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onPhotoCaptureMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Center(
            child: EteeloButton.primary(
              label: l10n.photoSessionFinish,
              fullWidth: false,
              onPressed: onFinish,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }
}
