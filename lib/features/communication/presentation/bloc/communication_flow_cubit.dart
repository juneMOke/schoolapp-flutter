import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';

/// L'écran montré dans Communication ▸ Communiqués. La navigation reste dans
/// la page : la liste garde ses filtres au retour, sans route à rejouer.
sealed class CommunicationScreen extends Equatable {
  const CommunicationScreen();

  @override
  List<Object?> get props => const [];
}

final class CommunicationListScreen extends CommunicationScreen {
  const CommunicationListScreen();
}

/// L'éditeur : un communiqué existant, ou un neuf pré-rempli par [seed].
final class CommunicationEditorScreen extends CommunicationScreen {
  final Announcement? announcement;
  final AnnouncementContent seed;

  /// Change à chaque ouverture : deux « Nouveau » de suite ne réutilisent pas
  /// le même éditeur.
  final int session;

  const CommunicationEditorScreen({
    required this.session,
    this.announcement,
    this.seed = const AnnouncementContent(),
  });

  @override
  List<Object?> get props => [announcement?.id, seed, session];
}

/// Un communiqué envoyé, en lecture seule.
final class CommunicationDetailScreen extends CommunicationScreen {
  final Announcement announcement;

  const CommunicationDetailScreen(this.announcement);

  @override
  List<Object?> get props => [announcement];
}

/// Les modèles de l'école, pour en choisir un.
final class CommunicationTemplatePickScreen extends CommunicationScreen {
  const CommunicationTemplatePickScreen();
}

class CommunicationFlowCubit extends Cubit<CommunicationScreen> {
  CommunicationFlowCubit() : super(const CommunicationListScreen());

  var _session = 0;

  void showList() => emit(const CommunicationListScreen());

  void openNew({AnnouncementContent seed = const AnnouncementContent()}) =>
      emit(CommunicationEditorScreen(session: ++_session, seed: seed));

  /// Un envoyé s'ouvre en détail ; le reste dans l'éditeur.
  void open(Announcement announcement) => emit(
    announcement.status == AnnouncementStatus.sent
        ? CommunicationDetailScreen(announcement)
        : CommunicationEditorScreen(
            session: ++_session,
            announcement: announcement,
          ),
  );

  void pickTemplate() => emit(const CommunicationTemplatePickScreen());
}
