import 'package:flutter/widgets.dart';

class AppRadius {
  AppRadius._();

  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);
  static const Radius card = Radius.circular(20);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius brSm = BorderRadius.all(sm);
  static const BorderRadius brMd = BorderRadius.all(md);
  static const BorderRadius brLg = BorderRadius.all(lg);
  static const BorderRadius brCard = BorderRadius.all(card);
  static const BorderRadius brPill = BorderRadius.all(pill);
}
