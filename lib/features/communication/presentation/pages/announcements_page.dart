import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/communication_flow_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcement_editor_page.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/list/announcements_list_screen.dart';

/// Communication ▸ Communiqués : la liste, l'éditeur et le détail, dans la
/// même page. La liste et ses filtres survivent au passage par les autres.
class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final yearId = context
        .read<AcademicYearContextBloc>()
        .state
        .context
        ?.academicYear
        .id;
    return MultiBlocProvider(
      providers: [
        BlocProvider<AnnouncementsCubit>(
          create: (_) =>
              GetIt.instance<AnnouncementsCubit>()
                ..load(academicYearId: yearId),
        ),
        BlocProvider<CommunicationFlowCubit>(
          create: (_) => CommunicationFlowCubit(),
        ),
      ],
      child: _AnnouncementsFlow(academicYearId: yearId),
    );
  }
}

class _AnnouncementsFlow extends StatelessWidget {
  final String? academicYearId;

  const _AnnouncementsFlow({required this.academicYearId});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CommunicationFlowCubit, CommunicationScreen>(
        builder: (context, screen) {
          final flow = context.read<CommunicationFlowCubit>();
          return switch (screen) {
            CommunicationEditorScreen() => AnnouncementEditorPage(
              key: ValueKey(screen.session),
              screen: screen,
              academicYearId: academicYearId,
            ),
            _ => AppPageBackground(
              scrollable: true,
              child: AnnouncementsListScreen(
                onOpen: flow.open,
                // Sans le droit d'envoyer, rien ne se rédige : la liste se lit.
                onCreate:
                    PermissionGate.allowsAccess(
                      context,
                      kAnnouncementSendAccess,
                    )
                    ? flow.openNew
                    : null,
              ),
            ),
          };
        },
      );
}
