import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/features/documents/data/ticket/mono_png_decoder.dart';
import 'package:school_app_flutter/features/school/data/local/school_logo_cache_dao.dart';

/// Tire les octets du logo quand l'empreinte du lot diffère de celle détenue.
///
/// ## La règle qui décide de tout
///
/// Il y a deux empreintes, et **l'en-tête conditionnel se construit
/// exclusivement sur celle qu'on DÉTIENT** — jamais sur celle que le lot
/// référentiel annonce.
///
/// Construit sur la cible, un `If-None-Match` produit un `304` **définitif**
/// après un tirage raté : le serveur répond « rien de neuf » sur une empreinte
/// qu'on n'a pas, et les octets n'arrivent jamais. L'état est stable, silencieux
/// et sans erreur à montrer — la pire des trois formes. Ligne absente ⇒ **aucun
/// en-tête**, donc `200` et les octets, ce que le contrat serveur garantit par
/// un test.
///
/// ## Pourquoi les octets sont vérifiés avant d'être rangés
///
/// Ranger des octets abîmés avec l'empreinte que le serveur annonce créerait
/// exactement le même piège : la tablette prétendrait détenir une image qu'elle
/// n'a pas, le prochain `If-None-Match` obtiendrait `304`, et le logo resterait
/// absent **pour toujours**, sans erreur nulle part.
///
/// La vérification est **structurelle** plutôt que cryptographique : la bande
/// thermique n'est rangée que si elle se décode en bande exploitable, ce qui
/// écarte une réponse tronquée ou corrompue en transit. `package:crypto`
/// permettrait de comparer l'empreinte elle-même — pour les DEUX variantes — mais
/// il n'est aujourd'hui qu'une dépendance transitive du projet, et l'importer
/// sans le déclarer casserait au premier changement de résolution. Le déclarer
/// est un arbitrage qui touche `pubspec`, et il n'est pas pris ici.
class SchoolLogoFetcher {
  final Dio _dio;
  final SchoolLogoCacheDao _cache;
  final DateTime Function() _now;

  SchoolLogoFetcher({
    required Dio dio,
    required SchoolLogoCacheDao cache,
    DateTime Function()? now,
  }) : _dio = dio,
       _cache = cache,
       _now = now ?? DateTime.now;

  /// Aligne le cache sur [targetSha], l'empreinte que le lot référentiel
  /// annonce pour cette variante.
  ///
  /// [targetSha] à `null` signifie **cette école n'a pas de logo** : la ligne est
  /// évacuée, sans quoi une école qui retire son sceau continuerait de l'imprimer.
  ///
  /// Ne lève jamais. Un tirage raté laisse le cache tel quel — donc la bande
  /// précédente si elle existe, et rien sinon. Un ticket sans logo reste un
  /// ticket juste ; un ticket au mauvais logo ne l'est pas.
  Future<void> ensureFresh({
    required String schoolId,
    required SchoolLogoVariant variant,
    required String? targetSha,
  }) async {
    try {
      if (targetSha == null || targetSha.trim().isEmpty) {
        await _cache.delete(schoolId, variant);
        return;
      }

      final held = await _cache.findSha(schoolId, variant);
      if (held == targetSha) return;

      final response = await _dio.get<List<int>>(
        '/api/v1/schools/$schoolId/logo/${variant.dbValue}',
        options: Options(
          responseType: ResponseType.bytes,
          // Sur ce que la tablette DÉTIENT, et seulement si elle détient
          // quelque chose. Le serveur accepte l'empreinte nue comme entre
          // guillemets ; on l'envoie telle qu'on la stocke.
          headers: held == null ? null : {'If-None-Match': held},
          // Le `304` et le `404` sont des réponses, pas des pannes : les
          // laisser passer évite de les traiter par une exception.
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      switch (response.statusCode) {
        case 200:
          await _store(schoolId, variant, response, targetSha);
        case 304:
          // Rien à faire : ce que l'on détient est à jour. Ce cas ne peut pas
          // survenir sans en-tête envoyé — s'il survenait, ce serait un défaut
          // serveur, et ne rien ranger reste la bonne réponse.
          return;
        case 404:
          // L'école n'a plus de logo côté serveur, alors que le lot en
          // annonçait un. Le cache se range sur le serveur, pas sur le lot.
          await _cache.delete(schoolId, variant);
        default:
          // 403 et le reste : on ne touche à rien. Un droit manquant n'est pas
          // une raison d'effacer ce que la tablette a déjà servi hors ligne.
          return;
      }
    } catch (_) {
      // Réseau coupé, réponse illisible, écriture refusée : le cache reste ce
      // qu'il était. Le repli est l'absence d'un ajout, jamais une dégradation.
      return;
    }
  }

  Future<void> _store(
    String schoolId,
    SchoolLogoVariant variant,
    Response<List<int>> response,
    String targetSha,
  ) async {
    final data = response.data;
    if (data == null || data.isEmpty) return;
    final bytes = Uint8List.fromList(data);

    // La bande thermique est rangée **seulement si elle se décode**. Une
    // réponse tronquée franchirait autrement la porte, et son empreinte
    // annoncerait une image que la tablette n'a pas.
    if (variant == SchoolLogoVariant.thermal) {
      final band = MonoPngDecoder.decode(bytes);
      if (band == null || !band.isUsable) return;
    } else if (!_looksLikePng(bytes)) {
      // La variante d'écran n'est pas décodée ici — Flutter s'en charge — mais
      // une réponse qui n'est même pas un PNG n'a rien à faire en cache.
      return;
    }

    // L'empreinte rangée est celle que le serveur vient de servir, pas celle
    // que le lot annonçait : les deux coïncident normalement, et en cas d'écart
    // c'est ce qu'on DÉTIENT qui doit être décrit.
    final served = _etagOf(response) ?? targetSha;

    await _cache.put(
      schoolId: schoolId,
      variant: variant,
      sha256: served,
      bytes: bytes,
      fetchedAt: _now(),
    );
  }

  /// L'`ETag` de la réponse, débarrassé de ses guillemets et de son `W/`.
  ///
  /// Le serveur sert un ETag fort entre guillemets ; on le stocke **nu**, parce
  /// que c'est sous cette forme qu'il arrive dans le lot référentiel et que les
  /// deux doivent se comparer sans normalisation à chaque lecture.
  static String? _etagOf(Response<Object?> response) {
    final raw = response.headers.value('etag')?.trim();
    if (raw == null || raw.isEmpty) return null;
    final unweak = raw.startsWith('W/') ? raw.substring(2) : raw;
    final unquoted = unweak.startsWith('"') && unweak.endsWith('"')
        ? unweak.substring(1, unweak.length - 1)
        : unweak;
    return unquoted.isEmpty ? null : unquoted;
  }

  static bool _looksLikePng(Uint8List bytes) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
