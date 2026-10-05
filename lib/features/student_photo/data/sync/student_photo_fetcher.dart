import 'dart:typed_data';

import 'package:school_app_flutter/core/database/tenant/tenant_scope.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_blobs.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_api.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// Télécharge la photo d'un élève et en garde une copie chiffrée, marquée de
/// l'empreinte qu'elle reproduit.
///
/// Lié à l'école de son départ ([TenantScope]) : une copie arrivée après une
/// bascule d'école ne marquerait pas la ligne d'une autre base.
class StudentPhotoFetcher {
  final StudentPhotoApi _api;
  final StudentPhotoDao _photos;
  final StudentPhotoBlobs _blobs;
  final TenantScope _tenant;
  final Map<String, dynamic> _extras;

  const StudentPhotoFetcher({
    required StudentPhotoApi api,
    required StudentPhotoDao photos,
    required StudentPhotoBlobs blobs,
    required TenantScope tenant,
    required Map<String, dynamic> extras,
  }) : _api = api,
       _photos = photos,
       _blobs = blobs,
       _tenant = tenant,
       _extras = extras;

  /// Les octets de la photo d'empreinte [sha256] à [size]. Lève l'échec du
  /// transport tel quel : hors ligne, l'appelant se rabat sur ce qu'il a.
  ///
  /// [served] : l'empreinte que le flux donne aux octets de CETTE taille
  /// (l'`ETag` attendu) — le serveur ré-encode chaque taille, la vignette n'a
  /// pas l'empreinte de la grande photo. La copie reste marquée de [sha256],
  /// la version de la photo.
  Future<Uint8List> fetch(
    String studentId,
    String sha256,
    StudentPhotoSize size, {
    required String? served,
  }) => _tenant.run(() async {
    final download = await _api.download(_extras, studentId, size);
    // La photo a changé depuis la descente : montrée, mais pas gardée sous
    // une empreinte qui n'est pas la sienne. Le prochain pull la rattrapera.
    final etag = download.etag;
    final current = etag == null || served == null || etag == served;
    if (current &&
        download.bytes.isNotEmpty &&
        await _blobs.writeCache(studentId, size, download.bytes)) {
      await _photos.markCached(studentId, size, sha256: sha256);
    }
    return download.bytes;
  });
}
