import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';

/// La réponse brute de `GET …/app-releases/desktop/latest`.
class DesktopLatestWire {
  final String signedPayload;
  final String signature;
  final String? minimumSupported;
  final List<DesktopReleaseNotes> notesSince;

  const DesktopLatestWire({
    required this.signedPayload,
    required this.signature,
    required this.minimumSupported,
    required this.notesSince,
  });

  factory DesktopLatestWire.fromJson(Map<String, dynamic> json) {
    final signedPayload = json['signedPayload'];
    final signature = json['signature'];
    if (signedPayload is! String || signature is! String) {
      throw const FormatException('latest: signedPayload ou signature absents');
    }
    final minimum = json['minimumSupported'];
    final rawNotes = json['notesSince'];
    return DesktopLatestWire(
      signedPayload: signedPayload,
      signature: signature,
      minimumSupported: minimum is String ? minimum : null,
      notesSince: [
        if (rawNotes is List)
          for (final entry in rawNotes)
            if (entry is Map<String, dynamic>) ?_notesOf(entry),
      ],
    );
  }

  /// Une entrée illisible est sautée : les notes ne servent qu'à l'affichage.
  static DesktopReleaseNotes? _notesOf(Map<String, dynamic> entry) {
    final version = AppVersion.tryParseStrict(entry['version'] as String?);
    if (version == null) return null;
    String text(String key) {
      final value = entry[key];
      return value is String ? value : '';
    }

    return DesktopReleaseNotes(
      version: version,
      notesFr: text('notesFr'),
      notesEn: text('notesEn'),
    );
  }
}

/// Lecture publique (sans jeton) de la dernière version de bureau. Le canal
/// est celui du back : il n'est pas passé.
class DesktopReleaseApi {
  final Dio _dio;

  DesktopReleaseApi(this._dio);

  /// `null` quand le back n'a aucune version pour ce canal (404).
  Future<DesktopLatestWire?> latest({
    required DesktopPlatform platform,
    required AppVersion since,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.desktopReleaseLatestEndpoint,
        queryParameters: {'platform': platform.wire, 'since': '$since'},
      );
      final data = response.data;
      if (data == null) throw const FormatException('latest: corps vide');
      return DesktopLatestWire.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
