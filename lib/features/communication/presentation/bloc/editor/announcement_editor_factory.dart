import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:uuid/uuid.dart';

/// Fabrique les éditeurs : chacun neuf (règle « BLoC en fabrique »), un UUID
/// tiré à l'ouverture d'un communiqué neuf.
class AnnouncementEditorFactory {
  final AnnouncementWriter _writer;
  final Uuid _uuid;
  final DateTime Function() _now;

  const AnnouncementEditorFactory({
    required AnnouncementWriter writer,
    required Uuid uuid,
    DateTime Function() now = DateTime.now,
  }) : _writer = writer,
       _uuid = uuid,
       _now = now;

  AnnouncementEditorCubit create({
    AnnouncementContent seed = const AnnouncementContent(),
    String? academicYearId,
  }) => AnnouncementEditorCubit.create(
    id: _uuid.v4(),
    writer: _writer,
    seed: seed,
    academicYearId: academicYearId,
    now: _now,
  );

  AnnouncementEditorCubit edit(
    Announcement announcement, {
    bool readOnly = false,
  }) => AnnouncementEditorCubit.edit(
    announcement: announcement,
    writer: _writer,
    readOnly: readOnly,
    now: _now,
  );
}
