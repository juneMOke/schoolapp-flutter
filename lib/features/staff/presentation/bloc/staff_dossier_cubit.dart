import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_content.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_document_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_dossier_state.dart';

/// Les pièces du dossier d'un agent : les relire, en verser, en ouvrir.
class StaffDossierCubit extends Cubit<StaffDossierState> {
  final LoadStaffDossierUseCase _load;
  final AddStaffDocumentUseCase _add;
  final OpenStaffDocumentUseCase _open;

  StaffDossierCubit({
    required LoadStaffDossierUseCase load,
    required AddStaffDocumentUseCase add,
    required OpenStaffDocumentUseCase open,
  }) : _load = load,
       _add = add,
       _open = open,
       super(const StaffDossierState());

  /// Relit le dossier. Une lecture ratée le laisse tel quel — rien n'est
  /// perdu, il se relira au prochain geste — mais met fin au chargement.
  Future<void> load(String staffMemberId) async {
    final result = await _load(staffMemberId);
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(loaded: true)),
      (dossier) => emit(state.copyWith(dossier: dossier, loaded: true)),
    );
  }

  /// Verse [document] sous [rawCode] ; rend `true` s'il est écrit.
  Future<bool> add(
    String staffMemberId,
    String rawCode,
    CapturedDocument document,
  ) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true));
    final result = await _add(staffMemberId, rawCode, document);
    if (isClosed) return false;
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          busy: false,
          outcome: StaffDocumentOutcome.saveFailed,
          failure: failure,
        ),
      );
      return false;
    }
    await load(staffMemberId);
    if (isClosed) return false;
    emit(state.copyWith(busy: false, outcome: StaffDocumentOutcome.saved));
    return true;
  }

  /// Les octets de [document], ou `null` — l'échec s'annonce par l'état.
  Future<StaffDocumentContent?> open(StaffDocument document) async {
    if (state.busy) return null;
    emit(state.copyWith(busy: true));
    final result = await _open(document);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            busy: false,
            outcome: StaffDocumentOutcome.openFailed,
            failure: failure,
          ),
        );
        return null;
      },
      (content) {
        emit(state.copyWith(busy: false));
        return content;
      },
    );
  }
}
