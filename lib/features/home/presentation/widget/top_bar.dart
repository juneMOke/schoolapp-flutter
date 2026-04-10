import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_notification_button.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_profile_menu_button.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_title.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(AppTheme.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        final isPreRegistrations =
            state.selectedSubMenuId == MenuConstants.preInscriptionsId;

        return AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTheme.surfaceColor,
          titleSpacing: 18,
          title: TopBarTitle(
            title: state.currentTitle,
            isPreRegistrations: isPreRegistrations,
          ),
          actions: [
            TopBarNotificationButton(onPressed: () {}),
            const SizedBox(width: 8),
            const TopBarProfileMenuButton(),
            const SizedBox(width: AppTheme.defaultPadding),
          ],
        );
      },
    );
  }
}
