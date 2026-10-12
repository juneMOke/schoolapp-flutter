import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ouvre Communication ▸ Communiqués : dans la coquille, par la navigation
/// interne ; hors coquille (route directe), par sa route.
void openAnnouncements(BuildContext context, {required String title}) {
  NavigationBloc? navigation;
  try {
    navigation = context.read<NavigationBloc>();
  } on ProviderNotFoundException {
    navigation = null;
  }
  if (navigation != null) {
    navigation.add(
      SubMenuItemSelected(
        menuId: MenuConstants.communicationMenuId,
        subMenuId: MenuConstants.communicationAnnouncementsId,
        title: title,
      ),
    );
    return;
  }
  GoRouter.maybeOf(context)?.go(AppRoutesNames.communicationAnnouncements);
}
