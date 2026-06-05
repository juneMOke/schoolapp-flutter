import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/home/presentation/widget/home_navigation_ui_tokens.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarLogoutButton extends StatelessWidget {
  const TopBarLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.logout,
      child: Material(
        color: AppColors.textOnDark.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            HomeNavigationUiTokens.topBarActionRadius,
          ),
          side: BorderSide(color: AppColors.textOnDark.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            HomeNavigationUiTokens.topBarActionRadius,
          ),
          onTap: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          child: const SizedBox(
            width: HomeNavigationUiTokens.topBarActionSize,
            height: HomeNavigationUiTokens.topBarActionSize,
            child: Icon(
              Icons.logout_rounded,
              color: AppColors.textOnDark,
              size: HomeNavigationUiTokens.topBarActionIconSize,
            ),
          ),
        ),
      ),
    );
  }
}
