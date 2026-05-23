import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class EnrollmentNavigationHelper {
  const EnrollmentNavigationHelper._();

  static void redirectToFirstRegistrationFromHome(BuildContext context) {
    context.goNamed(
      AppRoutesNames.home,
      queryParameters: {'subMenuId': MenuConstants.premiereInscriptionId},
    );
  }
}
