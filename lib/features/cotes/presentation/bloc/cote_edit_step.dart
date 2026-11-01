import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';

/// Ce qu'une frappe fait d'une cellule : son nouvel état, et son écriture.
class CoteEditStep {
  final CoteCell cell;

  /// Vrai si l'écriture doit partir au serveur.
  final bool sends;
  final Future<Either<Failure, Unit>> Function(String classroomId) write;

  const CoteEditStep({
    required this.cell,
    required this.sends,
    required this.write,
  });
}

/// Ce qu'une frappe change, `null` si rien : traverser une case, ou y remettre
/// ce qu'elle montre déjà, ne crée pas de cote.
CoteEditStep? nextCoteEdit(
  CotesRepository repository,
  CoteCell cell,
  CoteInput input,
  String raw,
) {
  final key = cell.key;
  CoteEditStep clearOnly() => CoteEditStep(
    cell: cell.withInvalidRaw(null),
    sends: false,
    write: (_) => repository.clearInvalid(key),
  );
  CoteEditStep draft(double? value) => CoteEditStep(
    cell: cell.withDraft(value),
    sends: true,
    write: (classroomId) =>
        repository.saveValue(classroomId: classroomId, key: key, value: value),
  );

  switch (input) {
    case CoteInputInvalid():
      if (cell.invalidRaw == raw) return null;
      return CoteEditStep(
        cell: cell.withInvalidRaw(raw),
        sends: false,
        write: (classroomId) => repository.saveInvalid(
          classroomId: classroomId,
          key: key,
          raw: raw,
        ),
      );
    case CoteInputEmpty():
      final hasOwnValue = cell.hasDraft
          ? cell.draftValue != null || cell.isRejected
          : cell.serverCote != null;
      if (hasOwnValue) return draft(null);
      return cell.invalidRaw == null ? null : clearOnly();
    case CoteInputValue(:final value):
      final shown = cell.displayedValue;
      final same = shown != null && toCentis(shown) == toCentis(value);
      if (same && !cell.isRejected) {
        return cell.invalidRaw == null ? null : clearOnly();
      }
      return draft(value);
  }
}
