import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ouvre le registre depuis le tableau de bord.
///
/// Dans la coquille, par la navigation interne : aucun critère n'est à porter
/// par la route — la période et le type pré-filtré passent par
/// `ExpensePeriodMemory`. Hors coquille (route directe), par la route du
/// registre, qui vit sous le même scope.
void openExpenseRegister(BuildContext context, {required String title}) {
  NavigationBloc? navigation;
  try {
    navigation = context.read<NavigationBloc>();
  } on ProviderNotFoundException {
    navigation = null;
  }
  if (navigation != null) {
    navigation.add(
      SubMenuItemSelected(
        menuId: MenuConstants.expenseMenuId,
        subMenuId: MenuConstants.expenseRegisterId,
        title: title,
      ),
    );
    return;
  }
  GoRouter.maybeOf(context)?.go(AppRoutesNames.expenseRegister);
}
