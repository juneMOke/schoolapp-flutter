import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

/// Ce qui écrit le programme : visible avec `academics.programme.write`
/// seulement (la direction lit, sans FAB ni actions), et gelé quand la
/// session ne permet pas d'écrire.
class ProgrammeWriteGate extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const ProgrammeWriteGate({super.key, required this.child, this.fallback});

  static const List<Perm> requires = [Perm.academicsProgrammeWrite];

  /// Lecture ponctuelle, pour les gestes déclenchés hors rendu.
  static bool allows(BuildContext context) =>
      PermissionGate.allows(context, requires);

  @override
  Widget build(BuildContext context) => PermissionGate(
    requires: requires,
    fallback: fallback,
    child: SessionWriteGate(child: child),
  );
}
