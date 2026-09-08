import 'package:school_app_flutter/features/documents/data/ticket/mono_png_decoder.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/school/data/local/school_logo_cache_dao.dart';

/// Sort du cache la bande de logo prête à poser en tête du ticket.
///
/// Le décodage a lieu **à l'impression**, pas au tirage : la table range le PNG
/// tel que le serveur l'a servi, ce qui garde ses octets comparables à leur
/// empreinte. Décoder à l'écriture obligerait à ranger une forme dérivée dont
/// plus rien ne dirait si elle correspond encore.
///
/// ## Rend `null` sur tout, et c'est le contrat
///
/// Aucune école, aucune ligne en cache, des octets qui ne décodent plus, une
/// base illisible : la réponse est la même. Le renderer reçoit alors une bande
/// nulle, `TicketLogoBand.isUsable` ne s'applique même pas, et le flux redevient
/// **identique à l'octet près** à celui d'un ticket sans logo.
///
/// C'est la propriété qui rend ce lot sûr : le repli n'est pas un cas à coder,
/// c'est l'absence d'un ajout. Un ticket sans logo reste un ticket juste ; un
/// encaissement qui n'imprime pas parce que le logo a échoué ne l'est pas.
class SchoolLogoBandLoader {
  final SchoolLogoCacheDao _cache;

  const SchoolLogoBandLoader(this._cache);

  /// La bande thermique de [schoolId], ou `null`.
  Future<TicketLogoBand?> thermalBand(String? schoolId) async {
    final id = schoolId?.trim();
    if (id == null || id.isEmpty) return null;
    try {
      final cached = await _cache.find(id, SchoolLogoVariant.thermal);
      if (cached == null) return null;
      final band = MonoPngDecoder.decode(cached.bytes);
      return (band != null && band.isUsable) ? band : null;
    } catch (_) {
      // Une base illisible ne doit pas empêcher un papier de sortir. Le logo
      // est décoratif ; le versement, lui, est déjà encaissé.
      return null;
    }
  }
}
