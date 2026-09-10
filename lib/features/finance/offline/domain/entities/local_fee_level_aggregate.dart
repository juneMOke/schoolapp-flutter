import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/recovery_position.dart';

/// Position d'un élève sur un frais, **rattachée au niveau que porte sa
/// créance** — la maille du tableau de bord du Contrôle des frais.
///
/// Enveloppe un [LocalFeeChargeAggregate] au lieu de redéclarer ses champs :
/// c'est ce qui garantit que le tableau de bord et l'écran de contrôle dérivent
/// le statut d'un élève par **la même règle**, jamais par deux copies qui
/// finiraient par diverger (FCD, invariant §6.1). Tout ce qui touche aux
/// montants — payé composé, reste, statut multi-devise — reste dit une seule
/// fois, là-bas.
class LocalFeeLevelAggregate extends Equatable implements RecoveryPosition {
  /// Niveau porté par les créances de cet élève sur ce frais.
  ///
  /// ⚠️ **Nullable, et la ligne est conservée quand même.** `school_level_id`
  /// est nullable au schéma : une créance *ad hoc*, ou descendue d'un serveur
  /// qui ne renseignait pas encore la colonne, n'a pas de niveau. La filtrer au
  /// SQL ferait disparaître des élèves d'un tableau de bord **sans rien dire**,
  /// et le total de l'école cesserait d'être la somme de ses niveaux. Le
  /// projecteur les regroupe donc sous un groupe « niveau non renseigné », qui
  /// se voit.
  @override
  final String? schoolLevelId;

  /// Position financière, à la lettre de l'écran de contrôle.
  final LocalFeeChargeAggregate charge;

  const LocalFeeLevelAggregate({
    required this.schoolLevelId,
    required this.charge,
  });

  @override
  String get studentId => charge.studentId;

  /// Reste dû de l'élève sur ce frais, par devise — la seule chose que le
  /// classement lit des montants.
  @override
  MoneyBag get remaining => charge.remaining;

  /// Statut de l'élève sur ce frais — **emprunté**, jamais recalculé.
  @override
  StudentChargeStatus get status => charge.status;

  @override
  List<Object?> get props => [schoolLevelId, charge];
}
