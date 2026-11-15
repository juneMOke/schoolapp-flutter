import 'package:school_app_flutter/core/offline/online_only.dart';

/// Un geste de paie qui n'existe qu'en ligne (voir [OnlineOnly]).
class PayrollOnlineOnly extends OnlineOnly {
  const PayrollOnlineOnly({super.key, required super.builder});
}
