import 'package:equatable/equatable.dart';

/// Corps de création d'un créneau de sonnerie (POST /time-slots).
///
/// [startTime]/[endTime] sont des **heures pures** `HH:mm:ss`. L'invariant
/// `endTime > startTime` est verrouillé côté backend (sinon HTTP 400 → mappé en
/// `validation`) : on ne le rejoue pas côté client puisque les heures sont
/// traitées comme des chaînes opaques (aucune conversion `DateTime`).
class CreateTimeSlotRequest extends Equatable {
  final int order;
  final String startTime;
  final String endTime;

  /// Libellé optionnel (max. 64 caractères côté backend).
  final String? label;

  const CreateTimeSlotRequest({
    required this.order,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  @override
  List<Object?> get props => [order, startTime, endTime, label];
}
