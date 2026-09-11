import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/day_enrollment_entry_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/day_enrollment_entry.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';

/// Une page de la liste nominative du jour.
///
/// Modèle **concret** plutôt que `PaginatedResponseModel<T>` : Retrofit
/// désérialise sur un `fromJson(Map)` à un seul paramètre, et la fabrique
/// générique en demande deux. C'est déjà le choix fait pour
/// `EnrollmentSummaryPageModel`, sur le même endpoint paginé.
///
/// ## Le numéro de page s'appelle `number`
///
/// ⚠️ Le serveur rend une `Page` Spring **sérialisée telle quelle** : le numéro
/// de page y est `number`, et **aucun champ `page` n'existe**. Ce modèle lisait
/// `page`, avec un repli à 0 — la page lue était donc toujours la première, et
/// la pagination de l'écran n'avançait jamais.
///
/// Les trois formes que ce contrat peut prendre sont lues :
///
///  * `number` à la racine — la `Page` Spring brute, servie aujourd'hui ;
///  * un objet `page` imbriqué portant `number`, `size`, `totalElements` et
///    `totalPages` — le `PagedModel` que Spring Data propose à la place, et
///    vers lequel le serveur peut basculer d'une ligne de configuration ;
///  * un entier `page` à la racine — la forme des DTO de page maison.
class DayEntriesPageModel {
  final List<DayEnrollmentEntryModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const DayEntriesPageModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory DayEntriesPageModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List<dynamic>?;
    final nested = json['page'];
    final meta = nested is Map<String, dynamic> ? nested : json;

    return DayEntriesPageModel(
      content: (rawContent ?? const <dynamic>[])
          .map(
            (item) =>
                DayEnrollmentEntryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      page: _intOf(meta['number']) ?? _intOf(nested) ?? 0,
      size: _intOf(meta['size']) ?? 0,
      totalElements: _intOf(meta['totalElements']) ?? 0,
      totalPages: _intOf(meta['totalPages']) ?? 0,
    );
  }

  /// Un nombre, quelle que soit la façon dont il a traversé le JSON ; `null`
  /// pour tout le reste — y compris l'objet `page` imbriqué, qui n'est pas un
  /// numéro.
  static int? _intOf(Object? value) => value is num ? value.toInt() : null;

  PaginatedResponse<DayEnrollmentEntry> toEntity() =>
      PaginatedResponse<DayEnrollmentEntry>(
        content: content.map((item) => item.toEntity()).toList(growable: false),
        page: page,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
      );
}
