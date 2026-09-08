import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
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
/// La vérification est **double**, et les deux moitiés n'attrapent pas la même
/// chose :
///
/// * **le condensat** doit correspondre à l'`ETag` reçu. Le serveur sert en
///   `ETag` le `sha256` des octets exacts de la réponse : la réponse porte donc
///   sa propre référence d'intégrité, et la comparer écarte des octets
///   **corrompus qui décoderaient quand même**. C'est la seule garde qui couvre
///   aussi la variante d'écran, qui n'est pas décodée ici ;
/// * **le décodage** de la bande thermique doit aboutir à une bande
///   exploitable. Une image dont le condensat est juste peut rester inutilisable
///   — mauvaises dimensions, largeur non multiple de huit — et la ranger
///   ferait croire à un logo qui ne s'imprimera jamais.
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

    // ── Première garde : le condensat.
    //
    // Le serveur sert en `ETag` le `sha256` des octets exacts de la réponse, si
    // bien qu'elle porte sa propre référence d'intégrité. Recalculer et comparer
    // écarte des octets **corrompus qui décoderaient quand même** — ce qu'aucun
    // décodage réussi ne peut voir — et c'est la seule garde qui couvre aussi la
    // variante d'écran.
    //
    // L'`ETag` fait foi, avec l'empreinte du lot en repli : c'est ce que le
    // serveur vient de servir qui décrit ce qu'on détient, pas ce qu'un pull
    // antérieur annonçait.
    final expected = _etagOf(response) ?? targetSha;
    final computed = await sha256Hex(bytes);
    if (computed != expected) return;

    // ── Seconde garde : la bande doit être EXPLOITABLE.
    //
    // Un condensat juste ne dit rien des dimensions. Une image intacte mais
    // large de 100 points, ou haute de zéro, ferait croire à un logo qui ne
    // s'imprimera jamais.
    if (variant == SchoolLogoVariant.thermal) {
      final band = MonoPngDecoder.decode(bytes);
      if (band == null || !band.isUsable) return;
    } else if (!_looksLikePng(bytes)) {
      // La variante d'écran n'est pas décodée ici — Flutter s'en charge — mais
      // une réponse qui n'est même pas un PNG n'a rien à faire en cache.
      return;
    }

    await _cache.put(
      schoolId: schoolId,
      variant: variant,
      // `computed`, pas `expected` : les deux sont égaux à ce point, et ranger
      // celui qu'on a CALCULÉ sur les octets détenus dit exactement ce que la
      // ligne décrit.
      sha256: computed,
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
