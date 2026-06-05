import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Enrollment listing layout gaps.
  static const double gridGap = 14;
  static const double sectionGap = 20;

  // Carte d'étape du stepper (PARCOURS 19).
  static const double stepCardHeaderV = 22;
  static const double stepCardHeaderH = 26;
  static const double stepCardBody = 26;

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}
