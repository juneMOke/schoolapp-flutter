import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/attachments/ephemeral_attachment_cache.dart';

/// Pourquoi une pièce n'a pas pu être ouverte.
enum AttachmentFetchError {
  /// Pas de réseau, et la pièce n'est pas dans le dossier temporaire.
  offline,

  /// Le serveur refuse (droit retiré, pièce disparue) ou répond mal.
  unavailable,
}

/// Le résultat d'un [AttachmentFetcher.fetch] : les octets, ou la raison.
sealed class AttachmentFetch {
  const AttachmentFetch();
}

class AttachmentFetched extends AttachmentFetch {
  final Uint8List bytes;

  const AttachmentFetched(this.bytes);
}

class AttachmentFetchFailed extends AttachmentFetch {
  final AttachmentFetchError error;

  const AttachmentFetchFailed(this.error);
}

/// Télécharge une pièce à la demande, en passant par le dossier temporaire.
///
/// Une pièce déjà là est **revalidée** par `If-None-Match` (l'`ETag` est son
/// `sha256`) : un 304 la rend sans transfert. Hors connexion, elle est rendue
/// telle quelle — elle ne peut pas avoir changé, son empreinte est sa clé.
///
/// Écrit sur Dio et non sur Retrofit : la réponse est binaire et le 304 doit
/// se lire comme une issue, pas comme une erreur.
class AttachmentFetcher {
  final Dio _dio;
  final EphemeralAttachmentCache _cache;

  const AttachmentFetcher(this._dio, this._cache);

  /// La pièce [ref], servie par [path] (déjà résolu, paramètres compris).
  Future<AttachmentFetch> fetch({
    required String path,
    required AttachmentRef ref,
    required Map<String, dynamic> extras,
  }) async {
    final cached = await _cache.read(ref.sha256);
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(
          extra: extras,
          responseType: ResponseType.bytes,
          headers: {if (cached != null) 'If-None-Match': '"${ref.sha256}"'},
          // Le 304 est une réponse attendue, pas une erreur.
          validateStatus: (status) =>
              status != null && (status == 304 || status < 300),
        ),
      );
      if (response.statusCode == 304 && cached != null) {
        return AttachmentFetched(cached);
      }
      final bytes = Uint8List.fromList(response.data ?? const []);
      if (bytes.isEmpty) {
        return const AttachmentFetchFailed(AttachmentFetchError.unavailable);
      }
      await _cache.write(ref.sha256, bytes);
      return AttachmentFetched(bytes);
    } on DioException catch (e) {
      if (e.response == null) {
        return cached != null
            ? AttachmentFetched(cached)
            : const AttachmentFetchFailed(AttachmentFetchError.offline);
      }
      return const AttachmentFetchFailed(AttachmentFetchError.unavailable);
    }
  }

  /// La pièce est-elle lisible sans réseau ?
  Future<bool> isCached(AttachmentRef ref) => _cache.contains(ref.sha256);
}
