import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/communication/data/wire/announcement_wire.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';

/// Les modèles de l'école, sur Dio.
class AnnouncementTemplateApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const AnnouncementTemplateApi(this._dio, this._extras);

  Options get _options => Options(extra: _extras);

  Future<List<AnnouncementTemplate>> list() async {
    final response = await _dio.get<Object?>(
      AppConstants.announcementTemplatesEndpoint,
      options: _options,
    );
    return AnnouncementWire.templatesFromJson(response.data);
  }

  Future<AnnouncementTemplate> create({
    required AnnouncementCategory category,
    required String title,
    required String body,
  }) async {
    final response = await _dio.post<Object?>(
      AppConstants.announcementTemplatesEndpoint,
      data: AnnouncementWire.templateToJson(
        category: category,
        title: title,
        body: body,
      ),
      options: _options,
    );
    return _read(response.data);
  }

  Future<AnnouncementTemplate> update(AnnouncementTemplate template) async {
    final response = await _dio.put<Object?>(
      _one(template.id),
      data: AnnouncementWire.templateToJson(
        category: template.category,
        title: template.title,
        body: template.body,
      ),
      options: _options,
    );
    return _read(response.data);
  }

  Future<void> delete(String id) =>
      _dio.delete<Object?>(_one(id), options: _options);

  static String _one(String id) => AppConstants.announcementTemplateEndpoint
      .replaceFirst('{id}', Uri.encodeComponent(id));

  static AnnouncementTemplate _read(Object? body) =>
      AnnouncementWire.templateFromJson(body) ??
      (throw const FormatException('Modèle illisible'));
}
