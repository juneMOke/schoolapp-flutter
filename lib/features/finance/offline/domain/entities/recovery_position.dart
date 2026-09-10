import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Ce qu'une projection de recouvrement lit d'un élève, et **rien de plus**.
///
/// Deux lectures alimentent les mêmes projecteurs : celle de l'écran de
/// contrôle, bornée à un frais, et celle du tableau de bord, portant une
/// sélection. Elles ne portent pas les mêmes détails — l'une ignore le
/// `fee_code`, l'autre le garde — mais le **classement** n'a besoin ni de l'un
/// ni de l'autre : il compte des élèves par groupe et somme des restes.
///
/// Cette interface est ce qui permet aux deux de partager un seul projecteur,
/// donc un seul tri, un seul comptage et une seule définition de « en ordre ».
/// Sans elle, deux copies auraient fini par diverger — et les deux écrans du
/// module se seraient contredits sur le même élève.
abstract interface class RecoveryPosition {
  String get studentId;

  /// Niveau porté par les créances. **`null` est une valeur légitime**, pas une
  /// absence à masquer : le grand-livre l'autorise, et les créances qui n'en
  /// portent pas forment un groupe qui se voit.
  String? get schoolLevelId;

  /// Statut sur le périmètre lu — emprunté à la règle du module, jamais
  /// recalculé par un projecteur.
  StudentChargeStatus get status;

  /// Reste dû, **par devise**, planché créance par créance.
  MoneyBag get remaining;
}
