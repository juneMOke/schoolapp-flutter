import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspended_members_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/show_suspended_toggle.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspended_members_section.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_changes_listener.dart';

/// La désactivation dans la composition d'un niveau : la bascule « Afficher
/// les désactivés (N) » de la synthèse, la section des élèves hors effectif,
/// et la relecture des rosters quand une désactivation change.
class ClassesSuspensionPanel extends StatefulWidget {
  final String academicYearId;

  /// Classes du niveau, par id → nom : seuls leurs élèves comptent ici.
  final Map<String, String> classNames;
  final VoidCallback onChanged;
  final Widget Function(
    BuildContext context,
    Widget? summaryAccessory,
    Widget? afterSummary,
  )
  builder;

  const ClassesSuspensionPanel({
    super.key,
    required this.academicYearId,
    required this.classNames,
    required this.onChanged,
    required this.builder,
  });

  @override
  State<ClassesSuspensionPanel> createState() => _ClassesSuspensionPanelState();
}

class _ClassesSuspensionPanelState extends State<ClassesSuspensionPanel> {
  /// Éteinte à chaque visite, non persistée.
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    if (widget.academicYearId.isEmpty) {
      return widget.builder(context, null, null);
    }
    return _withSuspensions(context);
  }

  Widget _withSuspensions(BuildContext context) => BlocProvider(
    create: (_) => getIt<SuspendedMembersCubit>(param1: widget.academicYearId),
    child: SuspensionChangesListener(
      onChanged: widget.onChanged,
      child: BlocBuilder<SuspendedMembersCubit, List<SuspendedMember>>(
        builder: (context, all) {
          final members = [
            for (final m in all)
              if (widget.classNames.containsKey(m.classroomId)) m,
          ];
          if (members.isEmpty) return widget.builder(context, null, null);
          return widget.builder(
            context,
            ShowSuspendedToggle(
              value: _show,
              count: members.length,
              onChanged: (value) => setState(() => _show = value),
            ),
            _show
                ? SuspendedMembersSection(
                    members: members,
                    classLabelOf: (id) => widget.classNames[id] ?? '',
                  )
                : null,
          );
        },
      ),
    ),
  );
}
