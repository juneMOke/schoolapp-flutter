import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/communication_flow_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/detail/announcement_detail_screen.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';

/// Le détail d'un envoyé, monté par la page Communiqués.
class AnnouncementDetailPage extends StatelessWidget {
  final CommunicationDetailScreen screen;

  const AnnouncementDetailPage({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    final flow = context.read<CommunicationFlowCubit>();
    final content = screen.announcement.content;
    return AppPageBackground(
      child: AnnouncementDetailScreen(
        announcement: screen.announcement,
        schoolName: context.read<SchoolIdentityCubit>().state.school?.name,
        onBack: flow.showList,
        // Le double reprend catégorie, titre, message, audience et canaux :
        // c'est un nouveau brouillon, sans lien avec l'envoyé.
        onDuplicate:
            PermissionGate.allowsAccess(context, kAnnouncementSendAccess)
            ? () => flow.openNew(
                seed: AnnouncementContent(
                  category: content.category,
                  title: content.title,
                  body: content.body,
                  audience: content.audience,
                  channels: content.channels,
                ),
              )
            : null,
      ),
    );
  }
}
