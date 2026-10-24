import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// L'ordre alphabétique du personnel : nom, puis post-nom, puis prénom — l'ordre
/// de l'état civil —, sans égard à la casse ni aux accents. « Élongo » se range
/// avec les E, pas après les Z.
///
/// L'identifiant départage deux homonymes parfaits : sans lui, leur ordre
/// dépendrait de la lecture de la base et changerait d'un rafraîchissement à
/// l'autre — et le PDF ne suivrait plus l'écran.
abstract final class HrNameOrder {
  static int compare(StaffMember a, StaffMember b) {
    for (final (left, right) in [
      (a.lastName, b.lastName),
      (a.middleName, b.middleName),
      (a.firstName, b.firstName),
    ]) {
      final order = _key(left).compareTo(_key(right));
      if (order != 0) return order;
    }
    return a.id.compareTo(b.id);
  }

  static String _key(String? value) =>
      SearchNormalizationHelper.normalize(value?.trim() ?? '');
}
