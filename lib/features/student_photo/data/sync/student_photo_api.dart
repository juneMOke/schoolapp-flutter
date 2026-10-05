import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_dto.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_request.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// Les octets d'une photo et l'empreinte que le serveur leur donne (`ETag`).
class StudentPhotoDownload {
  final Uint8List bytes;
  final String? etag;

  const StudentPhotoDownload({required this.bytes, this.etag});
}

/// Les quatre échanges de la photo d'un élève.
///
/// Écrits sur Dio et non sur Retrofit, comme les pièces du personnel : la
/// partie `metadata` d'une pose doit partir en `application/json`, ce que le
/// générateur ne sait pas dire d'une partie.
class StudentPhotoApi {
  final Dio _dio;

  const StudentPhotoApi(this._dio);

  static String _photoPath(String template, String studentId) =>
      template.replaceFirst('{studentId}', Uri.encodeComponent(studentId));

  /// Pose [jpeg] comme photo de l'élève ; rend l'état courant du serveur.
  Future<StudentPhotoStateDto> put(
    Map<String, dynamic> extras,
    StudentPhotoPushRequest request,
    Uint8List jpeg,
  ) async {
    final form = FormData.fromMap({
      'metadata': MultipartFile.fromString(
        jsonEncode(request.toMetadata()),
        contentType: DioMediaType('application', 'json'),
      ),
      'file': MultipartFile.fromBytes(
        jpeg,
        filename: '${request.studentId}.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });
    final response = await _dio.put<Object?>(
      _photoPath(AppConstants.syncStudentPhotoEndpoint, request.studentId),
      data: form,
      options: Options(extra: extras),
    );
    return StudentPhotoStateDto.parseAck(response.data);
  }

  /// Retire la photo de l'élève à la date du geste ; rend l'état courant.
  Future<StudentPhotoStateDto> delete(
    Map<String, dynamic> extras,
    StudentPhotoPushRequest request,
  ) async {
    final response = await _dio.delete<Object?>(
      _photoPath(AppConstants.syncStudentPhotoEndpoint, request.studentId),
      queryParameters: {'removedAt': request.at},
      options: Options(extra: extras),
    );
    return StudentPhotoStateDto.parseAck(response.data);
  }

  /// Une page du flux `student.photos`. Un 304 remonte en `DioException`,
  /// comme le lit `KeysetPullRunner`.
  Future<StudentPhotoPageDto> pull(
    Map<String, dynamic> extras,
    String? cursor,
    int limit,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppConstants.syncStudentPhotosEndpoint,
      queryParameters: {'cursor': ?cursor, 'limit': limit},
      options: Options(extra: extras),
    );
    return StudentPhotoPageDto.fromJson(response.data ?? const {});
  }

  /// Les octets de la photo de [studentId] à [size].
  Future<StudentPhotoDownload> download(
    Map<String, dynamic> extras,
    String studentId,
    StudentPhotoSize size,
  ) async {
    final response = await _dio.get<List<int>>(
      _photoPath(AppConstants.studentPhotoContentEndpoint, studentId),
      queryParameters: {'size': size.pixels},
      options: Options(extra: extras, responseType: ResponseType.bytes),
    );
    final etag = response.headers.value('etag');
    return StudentPhotoDownload(
      bytes: Uint8List.fromList(response.data ?? const []),
      etag: etag?.replaceAll('"', '').replaceFirst('W/', '').toLowerCase(),
    );
  }
}
