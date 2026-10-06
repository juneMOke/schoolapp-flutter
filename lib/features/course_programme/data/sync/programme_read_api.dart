import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';

/// La lecture **en ligne** du programme (P6) — celle de la direction, qui n'a
/// pas les cours sur sa tablette. Écrite sur Dio et lue à la main : la forme
/// de la réponse (liste nue ou `{chapitres: […]}`) est tolérée telle quelle.
class ProgrammeReadApi {
  final Dio _dio;

  const ProgrammeReadApi(this._dio);

  Future<List<ChapitreDto>> chapitresOfCours(
    Map<String, dynamic> extras,
    String coursId,
  ) async {
    final response = await _dio.get<Object?>(
      AppConstants.academicsCoursChapitresEndpoint.replaceFirst(
        '{coursId}',
        Uri.encodeComponent(coursId),
      ),
      options: Options(extra: extras),
    );
    final body = response.data;
    final raw = body is Map ? body['chapitres'] : body;
    return [
      if (raw is List)
        for (final item in raw) ?ChapitreDto.tryParse(item),
    ];
  }

  Future<ChapitreDto> chapitre(
    Map<String, dynamic> extras,
    String chapitreId,
  ) async {
    final response = await _dio.get<Object?>(
      AppConstants.academicsChapitreEndpoint.replaceFirst(
        '{chapitreId}',
        Uri.encodeComponent(chapitreId),
      ),
      options: Options(extra: extras),
    );
    final body = response.data;
    final dto = ChapitreDto.tryParse(
      body is Map ? body['chapitre'] ?? body : body,
    );
    if (dto == null) throw const FormatException('Chapitre illisible');
    return dto;
  }
}
