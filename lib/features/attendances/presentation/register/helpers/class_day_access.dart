import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_lock.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';

/// [classDayLock] avec les droits de la session lus dans [context] — l'unique
/// lecture des droits de l'appel, pour l'écran comme pour les gestes.
ClassDayLock? classDayLockIn(
  BuildContext context,
  ClassPresenceDay day, {
  required String today,
  bool justifying = false,
}) => classDayLock(
  day,
  today: today,
  canWrite: PermissionGate.allowsAccess(context, kAttendanceRecordAccess),
  canAmend: PermissionGate.allowsAccess(context, kAttendanceAmendAccess),
  justifying: justifying,
);
