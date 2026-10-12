import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';

/// Un communiqué tel que le serveur le tient.
///
/// L'[id] est un UUID **posé par la tablette** à la création : un `POST`
/// rejoué après un délai dépassé rend le même communiqué au lieu d'en créer
/// un second. [version] accompagne chaque geste — « on envoie ce qu'on a vu ».
class Announcement extends Equatable {
  final String id;
  final String? academicYearId;
  final AnnouncementContent content;
  final AnnouncementStatus status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? updatedAt;
  final String? lastSendError;

  /// La portée figée à l'envoi (« x sur N »), `null` avant.
  final AnnouncementReach? reachAtSend;
  final int version;

  const Announcement({
    required this.id,
    required this.content,
    required this.status,
    required this.version,
    this.academicYearId,
    this.scheduledAt,
    this.sentAt,
    this.updatedAt,
    this.lastSendError,
    this.reachAtSend,
  });

  /// La date qui situe le communiqué dans sa liste : envoi, programmation ou
  /// dernière modification, selon son statut.
  DateTime? get referenceDate => switch (status) {
    AnnouncementStatus.sent => sentAt ?? updatedAt,
    AnnouncementStatus.scheduled => scheduledAt ?? updatedAt,
    _ => updatedAt,
  };

  @override
  List<Object?> get props => [
    id,
    academicYearId,
    content,
    status,
    scheduledAt,
    sentAt,
    updatedAt,
    lastSendError,
    reachAtSend,
    version,
  ];
}
