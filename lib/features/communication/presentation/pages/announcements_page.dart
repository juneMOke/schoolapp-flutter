import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/communication_flow_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/pending_announcement_seed.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcement_detail_page.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcement_editor_page.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/list/announcements_list_screen.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/templates/templates_screen.dart';

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
        // Un modèle « utilisé » depuis le menu Modèles ouvre son brouillon
        // dès l'arrivée.
        BlocProvider<CommunicationFlowCubit>(
          create: (_) {
            final flow = CommunicationFlowCubit();
            final seed = GetIt.instance<PendingAnnouncementSeed>().take();
            if (seed != null) flow.openNew(seed: seed);
            return flow;
          },
        ),
      ],
      // Le contexte académique peut arriver après le montage (route directe,
      // rafraîchissement) : la liste se recharge sur l'année enfin connue.
      child: BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
        listenWhen: (prev, curr) =>
            prev.context?.academicYear.id != curr.context?.academicYear.id,
        listener: (context, state) => context.read<AnnouncementsCubit>().load(
          academicYearId: state.context?.academicYear.id,
        ),
        child: _AnnouncementsFlow(academicYearId: yearId),
      ),
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
          // Sans le droit d'envoyer, rien ne se rédige : la liste se lit.
          final canSend = PermissionGate.allowsAccess(
            context,
            kAnnouncementSendAccess,
          );
          return switch (screen) {
            CommunicationTemplatePickScreen() => BlocProvider(
              create: (_) =>
                  GetIt.instance<AnnouncementTemplatesCubit>()..load(),
              child: AppPageBackground(
                scrollable: true,
                child: TemplatesScreen(
                  onBack: flow.showList,
                  onUse: (template) => flow.openNew(
                    seed: AnnouncementContent(
                      category: template.category,
                      title: template.title,
                      body: template.body,
                    ),
                  ),
                ),
              ),
            ),
            CommunicationDetailScreen() => AnnouncementDetailPage(
              screen: screen,
            ),
            CommunicationEditorScreen() => AnnouncementEditorPage(
              key: ValueKey(screen.session),
              screen: screen,
              academicYearId: academicYearId,
            ),
            CommunicationListScreen() => AppPageBackground(
              scrollable: true,
              child: AnnouncementsListScreen(
                onOpen: flow.open,
                onCreate: canSend ? flow.openNew : null,
                onUseTemplate: canSend ? flow.pickTemplate : null,
              ),
            ),
          };
        },
      );
}
