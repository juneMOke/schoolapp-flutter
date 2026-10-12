import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';

typedef AnnouncementResult = Future<Either<Failure, Announcement>>;

/// Chaque étape réussie d'un enchaînement : l'appelant suit l'état serveur
/// même si l'étape suivante échoue (un brouillon créé, une version avancée).
typedef AnnouncementProgress = void Function(Announcement announcement);

/// Ce que l'éditeur veut obtenir, traduit en appels.
///
/// Le statut ne bouge que par un geste et `PUT` ne touche que le contenu :
/// enregistrer puis envoyer, c'est deux ou trois appels, chacun portant la
/// `version` que le précédent a rendue. Un échec en route laisse le
/// communiqué dans le dernier état atteint — jamais en double, puisque l'id
/// vient de la tablette.
class AnnouncementWriter {
  final AnnouncementRepository _repository;

  const AnnouncementWriter(this._repository);

  /// Un brouillon à jour : créé s'il n'existe pas, repassé en brouillon s'il
  /// était programmé ou en échec, son contenu remplacé s'il a changé.
  AnnouncementResult saveDraft({
    required String id,
    required AnnouncementContent content,
    Announcement? current,
    String? academicYearId,
    AnnouncementProgress? onStep,
  }) => _persist(
    id: id,
    content: content,
    current: current,
    academicYearId: academicYearId,
    keepScheduled: false,
    onStep: onStep,
  );

  /// Programmé à [scheduledAt]. Un programmé dont l'heure change est d'abord
  /// repassé en brouillon : `PUT` ne porte pas le moment.
  AnnouncementResult schedule({
    required String id,
    required AnnouncementContent content,
    required DateTime scheduledAt,
    Announcement? current,
    String? academicYearId,
    AnnouncementProgress? onStep,
  }) async {
    final sameMoment =
        current?.status == AnnouncementStatus.scheduled &&
        current?.scheduledAt?.toUtc() == scheduledAt.toUtc();
    final saved = await _persist(
      id: id,
      content: content,
      current: current,
      academicYearId: academicYearId,
      keepScheduled: sameMoment,
      onStep: onStep,
    );
    return saved.fold(Left.new, (announcement) {
      if (announcement.status == AnnouncementStatus.scheduled) {
        return Right(announcement);
      }
      return _repository.schedule(
        announcement.id,
        scheduledAt: scheduledAt,
        version: announcement.version,
      );
    });
  }

  /// Envoyé maintenant — depuis un brouillon, un programmé (« repasser
  /// Maintenant ») ou un échec. Un échec dont le contenu n'a pas bougé part
  /// tel quel.
  AnnouncementResult send({
    required String id,
    required AnnouncementContent content,
    Announcement? current,
    String? academicYearId,
    AnnouncementProgress? onStep,
  }) async {
    final saved = await _persist(
      id: id,
      content: content,
      current: current,
      academicYearId: academicYearId,
      keepScheduled: true,
      onStep: onStep,
    );
    return saved.fold(
      Left.new,
      (announcement) =>
          _repository.send(announcement.id, version: announcement.version),
    );
  }

  /// Retiré de la liste, sans effacement.
  AnnouncementResult cancel(Announcement current) =>
      _repository.cancel(current.id, version: current.version);

  /// L'état serveur à jour, après un refus pour version périmée.
  AnnouncementResult reload(String id) => _repository.get(id);

  AnnouncementResult _persist({
    required String id,
    required AnnouncementContent content,
    required Announcement? current,
    required String? academicYearId,
    required bool keepScheduled,
    AnnouncementProgress? onStep,
  }) async {
    if (current == null) {
      return _tap(
        await _repository.create(
          id: id,
          content: content,
          academicYearId: academicYearId,
        ),
        onStep,
      );
    }
    var announcement = current;
    final changed = announcement.content != content;
    // `PUT` n'accepte qu'un brouillon ou un programmé : un échec redevient
    // brouillon avant d'être réécrit, un programmé quand on le veut brouillon.
    final unschedule = switch (announcement.status) {
      AnnouncementStatus.failed => changed || !keepScheduled,
      AnnouncementStatus.scheduled => !keepScheduled,
      _ => false,
    };
    if (unschedule) {
      final result = await _repository.unschedule(
        announcement.id,
        version: announcement.version,
      );
      final next = result.fold((_) => null, (value) => value);
      if (next == null) return result;
      onStep?.call(next);
      announcement = next;
    }
    if (!changed) return Right(announcement);
    return _tap(
      await _repository.update(
        announcement.id,
        content,
        version: announcement.version,
      ),
      onStep,
    );
  }

  static Either<Failure, Announcement> _tap(
    Either<Failure, Announcement> result,
    AnnouncementProgress? onStep,
  ) {
    if (onStep != null) result.fold((_) {}, onStep);
    return result;
  }
}
