import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un adaptateur Dio qui rend [body] avec [status] et garde la requête.
class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.body, {this.status = 200});

  Object? body;
  int status;
  final List<RequestOptions> requests = [];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio dioWith(RecordingAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;

/// Un communiqué tel que le serveur le rend.
Map<String, Object?> announcementJson({
  String id = 'a-1',
  String status = 'DRAFT',
  String category = 'INFO',
  String title = 'Réunion des parents',
  String body = 'Chers parents de {eleve},\nréunion samedi.',
  Map<String, Object?> audience = const {'mode': 'SCHOOL'},
  int version = 3,
  String? scheduledAt,
  String? sentAt,
  String updatedAt = '2026-10-12T08:00:00Z',
  Map<String, Object?>? reachAtSend,
}) => {
  'id': id,
  'academicYearId': 'y-1',
  'category': category,
  'title': title,
  'body': body,
  'audience': audience,
  'channels': ['WHATSAPP'],
  'status': status,
  'scheduledAt': scheduledAt,
  'sentAt': sentAt,
  'updatedAt': updatedAt,
  'version': version,
  'reachAtSend': reachAtSend,
};

Announcement announcement({
  String id = 'a-1',
  AnnouncementStatus status = AnnouncementStatus.draft,
  AnnouncementCategory category = AnnouncementCategory.info,
  String title = 'Réunion des parents',
  String body = 'Réunion samedi.',
  AnnouncementAudience audience = const SchoolAudience(),
  int version = 1,
  DateTime? scheduledAt,
  DateTime? sentAt,
  DateTime? updatedAt,
  AnnouncementReach? reachAtSend,
  String? lastSendError,
}) => Announcement(
  id: id,
  content: AnnouncementContent(
    category: category,
    title: title,
    body: body,
    audience: audience,
  ),
  status: status,
  version: version,
  scheduledAt: scheduledAt,
  sentAt: sentAt,
  updatedAt: updatedAt ?? DateTime.utc(2026, 10, 12, 8),
  reachAtSend: reachAtSend,
  lastSendError: lastSendError,
);

const reach = AnnouncementReach(
  students: 104,
  guardians: 95,
  messages: 120,
  reachableMessages: 113,
  guardiansWithoutPhone: 6,
  studentsUnreachable: 4,
  whatsappEnabled: true,
);

/// L'hôte d'un écran du module : localisations françaises, un `Scaffold`.
Widget communicationHost(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
