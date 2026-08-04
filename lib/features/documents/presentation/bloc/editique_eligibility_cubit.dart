import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/is_student_known_to_server_use_case.dart';

/// Une pièce d'éditique scopée élève est-elle **demandable** pour cet élève ?
///
/// L'émission est une opération 100 % serveur : elle prend le `studentId` dans
/// le chemin de l'URL. Un élève saisi hors ligne porte un uuid **client** que le
/// serveur n'a pas encore honoré — l'appel répondrait 404, et sur une pièce non
/// archivée (relevé, quitus) un rejeu ultérieur brûlerait un numéro de séquence.
///
/// Ce cubit n'est donc pas un confort d'affichage mais une **garde de
/// correction** : sans lui, la Facturation propose un relevé de compte qui ne
/// peut pas aboutir dès que le dossier de l'élève n'est pas encore synchronisé.
class EditiqueEligibilityCubit extends Cubit<EditiqueEligibilityState> {
  final IsStudentKnownToServerUseCase _isStudentKnownToServer;

  EditiqueEligibilityCubit(this._isStudentKnownToServer)
    : super(const EditiqueEligibilityState());

  /// Résout l'éligibilité de [studentId]. **Fail-closed** : un échec de lecture
  /// locale laisse l'action éteinte plutôt que de la rouvrir sur une supposition.
  Future<void> resolveForStudent(String studentId) async {
    if (isClosed) return;
    emit(const EditiqueEligibilityState());

    final result = await _isStudentKnownToServer(studentId);
    if (isClosed) return;

    emit(
      result.fold(
        (_) => const EditiqueEligibilityState(
          status: EditiqueEligibilityStatus.blocked,
        ),
        (known) => EditiqueEligibilityState(
          status: known
              ? EditiqueEligibilityStatus.eligible
              : EditiqueEligibilityStatus.blocked,
        ),
      ),
    );
  }
}

enum EditiqueEligibilityStatus {
  /// Résolution en cours — l'action reste éteinte le temps de savoir.
  resolving,

  /// L'identifiant est connu du serveur : l'émission peut partir.
  eligible,

  /// L'identifiant n'est pas (encore) connu du serveur, ou n'a pas pu être
  /// vérifié. L'action est éteinte et l'UI annonce la mise en attente.
  blocked,
}

class EditiqueEligibilityState extends Equatable {
  final EditiqueEligibilityStatus status;

  const EditiqueEligibilityState({
    this.status = EditiqueEligibilityStatus.resolving,
  });

  /// Seul état qui autorise une émission. `resolving` n'ouvre rien : tant qu'on
  /// ne sait pas, on n'affirme pas.
  bool get isEligible => status == EditiqueEligibilityStatus.eligible;

  /// Vrai quand l'ineligibilité est **établie** — et donc explicable à
  /// l'utilisateur. Distinct de `!isEligible`, qui couvre aussi l'attente.
  bool get isBlocked => status == EditiqueEligibilityStatus.blocked;

  @override
  List<Object?> get props => [status];
}
