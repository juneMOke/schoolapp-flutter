import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_classroom_amount.dart';

/// Miroir de `TillClassroomAmountDto` — une ligne du palmarès des classes.
class TillClassroomAmountModel {
  final String classroomId;
  final String name;
  final int amount;

  const TillClassroomAmountModel({
    required this.classroomId,
    required this.name,
    required this.amount,
  });

  /// Une ligne de classement est un **ornement du total**, jamais le total :
  /// ses champs cèdent plutôt que de faire échouer la lecture de la caisse.
  /// Le montant du tiroir vit sur le résumé, et lui ne cède rien.
  factory TillClassroomAmountModel.fromJson(Map<String, dynamic> json) {
    return TillClassroomAmountModel(
      classroomId: ((json['classroomId'] as String?) ?? '').trim(),
      name: ((json['name'] as String?) ?? '').trim(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'classroomId': classroomId,
    'name': name,
    'amount': amount,
  };

  TillClassroomAmount toEntity() =>
      TillClassroomAmount(classroomId: classroomId, name: name, amount: amount);
}
