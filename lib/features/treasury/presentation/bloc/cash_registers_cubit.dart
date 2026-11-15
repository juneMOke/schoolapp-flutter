import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';

enum CashRegistersStatus { loading, ready, failure }

class CashRegistersState extends Equatable {
  final CashRegistersStatus status;
  final List<RegisterConfig> registers;
  final Failure? failure;

  const CashRegistersState({
    this.status = CashRegistersStatus.loading,
    this.registers = const [],
    this.failure,
  });

  @override
  List<Object?> get props => [status, registers, failure];
}

/// Trésorerie ▸ Configuration : les caisses de l'école.
///
/// Chaque écriture rend son échec (ou `null`) : c'est la modale qui le dit,
/// sous le champ concerné. Après un succès, la liste est **relue** au serveur
/// plutôt que recomposée ici : le solde, le compteur d'ajustements et la
/// clôture du jour sont des chiffres serveur, et un chiffre recalculé sur
/// l'appareil pourrait diverger de celui que la caisse affichera demain.
class CashRegistersCubit extends Cubit<CashRegistersState> {
  final CashRegistersRepository _repository;

  CashRegistersCubit(this._repository) : super(const CashRegistersState());

  Future<void> load() async {
    emit(const CashRegistersState());
    await _refresh();
  }

  Future<Failure?> create({
    required TreasuryCurrency currency,
    required String? name,
    required int openingAmountInCents,
  }) async {
    final result = await _repository.create(
      currency: currency,
      name: name,
      openingAmountInCents: openingAmountInCents,
    );
    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await _refresh();
    return failure;
  }

  /// L'ajustement enregistré (son numéro et son écart servent au toast), ou
  /// l'échec.
  Future<Either<Failure, CashAdjustment>> adjust({
    required String registerId,
    required String id,
    required int shownExpectedInCents,
    required int newAmountInCents,
    required String reason,
  }) async {
    final result = await _repository.adjust(
      registerId: registerId,
      id: id,
      shownExpectedInCents: shownExpectedInCents,
      newAmountInCents: newAmountInCents,
      reason: reason,
    );
    if (result.isRight()) await _refresh();
    return result;
  }

  /// Relit sans repasser par le squelette quand des caisses sont déjà
  /// affichées : un rechargement après un geste ne fait pas clignoter la page.
  Future<void> _refresh() async {
    final result = await _repository.list();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => state.registers.isEmpty
            ? CashRegistersState(
                status: CashRegistersStatus.failure,
                failure: failure,
              )
            : state,
        (registers) => CashRegistersState(
          status: CashRegistersStatus.ready,
          registers: registers,
        ),
      ),
    );
  }
}
