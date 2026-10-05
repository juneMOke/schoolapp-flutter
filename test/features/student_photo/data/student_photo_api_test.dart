import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_api.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_request.dart';

/// Rend l'état courant sans réseau, et garde la requête partie.
class _Capture extends Interceptor {
  RequestOptions? sent;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    sent = options;
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'studentId': 's-1',
          'removedAt': '2026-10-05T08:14:03.120Z',
          'serverUpdatedAt': '2026-10-05T08:14:05Z',
        },
      ),
    );
  }
}

void main() {
  test(
    'un retrait porte sa date ET son auteur, que le serveur exige',
    () async {
      final capture = _Capture();
      final dio = Dio()..interceptors.add(capture);

      final state = await StudentPhotoApi(dio).delete(
        const {},
        const StudentPhotoPushRequest(
          studentId: 's-1',
          op: StudentPhotoOp.delete,
          at: '2026-10-05T08:14:03.120Z',
          authorId: 'u-1',
        ),
      );

      expect(capture.sent!.method, 'DELETE');
      expect(capture.sent!.path, '/api/v1/sync/students/s-1/photo');
      expect(capture.sent!.queryParameters, {
        'removedAt': '2026-10-05T08:14:03.120Z',
        'authorId': 'u-1',
      });
      expect(state.sha256, isNull);
    },
  );
}
