import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/pending_announcement_seed.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/communication_navigation.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/template_actions.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/templates/templates_screen.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Communication ▸ Modèles.
class AnnouncementTemplatesPage extends StatelessWidget {
  const AnnouncementTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider<AnnouncementTemplatesCubit>(
        create: (_) => GetIt.instance<AnnouncementTemplatesCubit>()..load(),
        child: const AppPageBackground(
          scrollable: true,
          child: _TemplatesBody(),
        ),
      );
}

class _TemplatesBody extends StatelessWidget {
  const _TemplatesBody();

  @override
  Widget build(BuildContext context) {
    final actions = TemplateActions(
      context,
      context.read<AnnouncementTemplatesCubit>(),
    );
    final canWrite = PermissionGate.allowsAccess(
      context,
      kAnnouncementTemplateWriteAccess,
    );
    final canSend = PermissionGate.allowsAccess(
      context,
      kAnnouncementSendAccess,
    );
    return TemplatesScreen(
      onCreate: canWrite ? actions.create : null,
      onEdit: canWrite ? actions.edit : null,
      onDelete: canWrite ? actions.delete : null,
      onUse: canSend ? (template) => _use(context, template) : null,
    );
  }

  /// « Utiliser » : un brouillon pré-rempli, ouvert sur Communiqués. Audience
  /// et canaux reprennent leurs valeurs par défaut.
  static void _use(BuildContext context, AnnouncementTemplate template) {
    GetIt.instance<PendingAnnouncementSeed>().request(
      AnnouncementContent(
        category: template.category,
        title: template.title,
        body: template.body,
      ),
    );
    openAnnouncements(
      context,
      title: AppLocalizations.of(context)!.subMenuAnnouncements,
    );
  }
}
